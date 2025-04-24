import dynamicLinks from '@react-native-firebase/dynamic-links';
import { S3 } from 'aws-sdk';
import { Toast } from 'native-base';
import { PDFDocument, PDFPage } from 'pdf-lib';
import RNFS from 'react-native-fs';
import { v4 as uuidv4 } from 'uuid';

import { firestoreDB, getCurrentUser } from '../../Modules/auth/firebase/firebase';
import CrashlyticsService from '../../services/CrashlyticsService';
import PermissionsService from '../../services/PermissionsService';
import { addItemToDownloadingList, removeItemFromDownloadingList, setDownloadProgress, setIsDownloading, updateDownloadProgress } from './pdfViewerSlice';

import 'react-native-get-random-values';

class PdfViewerAction {
    static s3 = new S3({
        accessKeyId: "jw3kscoq6bbnq6cmvoojjpivjv7q",
        secretAccessKey: "jy3acenhwqj4owoa6533wkfbearkg656dwjoo3dudal7zwcyugrsg",
        endpoint: "https://gateway.storjshare.io",
        credentials: {
            accessKeyId: "jw3kscoq6bbnq6cmvoojjpivjv7q",
            secretAccessKey: "jy3acenhwqj4owoa6533wkfbearkg656dwjoo3dudal7zwcyugrsg",
        },
    });
    static listDownloadedFiles = async () => {
        try {
            const directoryPath = `${RNFS.DocumentDirectoryPath}/Resources`;
            const files = await RNFS.readdir(directoryPath);
            return files;
        } catch (error) {
            console.log('Error reading directory:', error);
        }
    };

    static getfileMetaData = async (notesDataArray) => {
        const metadataArray = [];

        for (const notesData of notesDataArray) {
            const setPdfDataPath = `${RNFS.DocumentDirectoryPath}/Resources/${notesData}`;

            const metadataFilePath = `${setPdfDataPath}`;

            try {
                const metadataJSON = await RNFS.readFile(metadataFilePath, 'utf8');
                const metadata = JSON.parse(metadataJSON);

                metadataArray.push(metadata);
            } catch (error) {
                console.log('Error reading metadata file:', error);
            }
        }

        return metadataArray;
    };


    static checkIfFileExists = async (notesData) => {
        const pdfFileName = `${notesData?.name}_${notesData?.branch}_${notesData?.sem}.pdf`
        const filePath = `${RNFS.DocumentDirectoryPath}/Resources/${pdfFileName}`;
        const fileExists = await RNFS.exists(filePath);
        if (fileExists) {
            return filePath;
        }
        return false;
    };
    
    static checkIfFileExistsInCache = async (path) => {
        const fileExists = await RNFS.exists(path);
        if (fileExists) {
            return path;
        }
        return false;
    };

    static createMetaData = (result, notesData, setPdfDataPath) => async (dispatch) => {
        const metaData = {
            ...notesData,
            status: 'Downloaded',
            downloadedDate: new Date(),
        };
        await RNFS.writeFile(setPdfDataPath, JSON.stringify(metaData), 'utf8');
        if (result.statusCode === 200) {
            dispatch(setIsDownloading(false));
            dispatch(setDownloadProgress());
            Toast.show({
                title: 'File Downloaded Successfully',
                type: 'success',
                backgroundColor: '#5cb85c',
                duration: 3000,
            });
        } else {
            dispatch(setIsDownloading(false));
            Toast.show({
                title: 'Error Downloading File',
                type: 'danger',
                backgroundColor: '#d9534f',
                duration: 3000,
            });
        }
    }

    static downloadFile = (notesData, url, setTaskId, setProgress) => async (dispatch) => {
        // Check for storage permission before downloading
        const hasPermission = await PermissionsService.requestStoragePermission();
        if (!hasPermission) {
            Toast.show({
                title: 'Cannot download without storage permission',
                duration: 3000,
                backgroundColor: '#d9534f',
            });
            return;
        }
        
        setProgress(0)
        const fileSize = notesData?.size / 1024;
        const pdfFileName = `${notesData?.name}_${notesData?.branch}_${notesData?.sem}.pdf`;
        const downloadDest = `${RNFS.DocumentDirectoryPath}/Resources/${pdfFileName}`;
        const setPdfDataPath = `${RNFS.DocumentDirectoryPath}/Resources/${pdfFileName}.text`;
        const options = {
            fromUrl: url,
            toFile: downloadDest,
            background: true,
            cache: true,
            progressDivider: fileSize < 10 ? 50 : 13,
            progress: (data) => {
                const progress = data.bytesWritten / data.contentLength;
                setProgress(progress)
            },
            begin: (res) => {
                setTaskId(res.jobId);
                dispatch(setIsDownloading(true));
                dispatch(addItemToDownloadingList({
                    ...notesData,
                    url: url,
                    jobId: res.jobId,
                    downloadedDate: new Date(),
                    progress: 0,
                    status: 'Downloading',
                }))
            }
        };

        RNFS.downloadFile(options).promise
            .then((res) => {
                dispatch(removeItemFromDownloadingList(url))
                dispatch(this.createMetaData(res, notesData, setPdfDataPath));
            }).catch((e) => {
                dispatch(removeItemFromDownloadingList(url))
                if (e.toString().includes('Download has been aborted')) {
                    Toast.show({
                        title: 'Download has been aborted',
                        backgroundColor: '#d9534f',
                        duration: 3000,
                    });
                }
                else {
                    Toast.show({
                        title: 'File Download Failed',
                        type: 'danger',
                        backgroundColor: '#d9534f',
                        duration: 3000,
                    });
                }
                dispatch(setIsDownloading(false))
                dispatch(setDownloadProgress());
            })
    };

    static download = (notesData, url, setTaskId) => (dispatch) => {
        const directoryPath = `${RNFS.DocumentDirectoryPath}/Resources`;
        RNFS.exists(directoryPath).then((directoryExists) => {
            if (directoryExists) {
                dispatch(this.downloadFile(notesData, url, setTaskId));
            } else {
                RNFS.mkdir(directoryPath);
                dispatch(this.downloadFile(notesData, url, setTaskId));
            }
        })
    };

    static sharePdf = async (notesData, dynamicLink) => {
      try {
        const queryParams = new URLSearchParams({
          category: notesData.category,
          university: notesData.university,
          course: notesData.course,
          branch: notesData.branch,
          sem: notesData.sem,
          subject: notesData.subject,
          did: notesData.did,
          units: notesData.units,
          name: notesData.name,
          id: notesData.id,
          page: 'viewPdf'
        });
        
        const link = await dynamicLinks().buildShortLink({
          link: `https://app.getacademically.co?${queryParams}`,
          domainUriPrefix: dynamicLink,
          android: {
            packageName: 'com.academically',
          },
        }, dynamicLinks.ShortLinkType.SHORT);
        
        return link;
      } catch (error) {
        CrashlyticsService.recordError(error);
        Toast.show({
          title: 'Something went wrong, Please try again later',
          duration: 3000,
        });
        return null;
      }
    }

    static stopDownload = (taskId) => {
        RNFS.stopDownload(taskId);
    }

    static deleteFile = async (notesData) => {
        try {
            const pdfFileName = `${notesData?.name}_${notesData?.branch}_${notesData?.sem}.pdf`
            const setPdfDataPath = `${RNFS.DocumentDirectoryPath}/Resources/${pdfFileName}.text`;
            const filePath = `${RNFS.DocumentDirectoryPath}/Resources/${pdfFileName}`;
            const fileExists = await RNFS.exists(filePath);
            if (fileExists) {
                await RNFS.unlink(filePath);
                await RNFS.unlink(setPdfDataPath);
            }
        }
        catch (error) {
            console.log('Error deleting file:', error);
        }
    };

    static manageBookmarks = async (notesData, status, uid) => {
        const bookMarkedElement = firestoreDB().collection(`Users/${uid}/NotesBookmarked`);

        try {
            !status ? await bookMarkedElement.doc(`${notesData?.id}`).set({
                ...notesData
            })
                :
                bookMarkedElement.doc(`${notesData?.id}`).delete()

        } catch (e) {
            CrashlyticsService.recordError(e)
        }
    }

    static removeBookmark = async (notesData, uid) => {
        try {
            await firestoreDB().collection(`Users/${uid}/NotesBookmarked`).doc(`${notesData?.id}`).delete();
        }
        catch (err) {
            CrashlyticsService.recordError(err);
        }
    }

    static handleCreateFile = async (notesData, url, splitPageNumbers, uid, setCurrentProgress, setStartedProcessing) => {
        setStartedProcessing(true)
        setCurrentProgress('Please wait, processing PDF..')
        const uniqueId = uuidv4();
        const outputPath = `Processed-pdfs/${notesData?.university}/${notesData?.course}/${notesData?.branch}/${notesData?.sem}/${notesData?.subject}/${notesData?.category}/${uniqueId}/${notesData?.name}`;
        const pdfUrl = `https://link.storjshare.io/s/jvn6w5kdxgoqla5jw3umlrspv7zq/academic-ally/${outputPath}?wrap=0`;
        const pdfPath = `${RNFS.DocumentDirectoryPath}/${notesData?.id}_${notesData?.name}`;
      
        try {
          // Maximum number of retries for server errors
          const MAX_RETRIES = 2;
          
          // Implement a retry wrapper for the uploadFileAndProcessPdf function
          const uploadWithRetry = async (retryCount = 0) => {
            try {
              return await this.uploadFileAndProcessPdf(
                pdfUrl,
                outputPath,
                uid,
                notesData,
                uniqueId,
                splitPageNumbers,
                setCurrentProgress,
                setStartedProcessing
              );
            } catch (error) {
              // Check if it's a 500 server error and we still have retries left
              if (error.message && error.message.includes('500') && retryCount < MAX_RETRIES) {
                setCurrentProgress(`Server error, retrying (${retryCount + 1}/${MAX_RETRIES})...`);
                // Wait a bit before retrying (exponential backoff)
                await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
                return uploadWithRetry(retryCount + 1);
              }
              // If we've exhausted retries or it's not a 500 error, rethrow
              throw error;
            }
          };
          
          if (splitPageNumbers.length === 0) {
            // Just upload the file without splitting
            return await uploadWithRetry();
          } else {
            // Download, split and then upload the PDF
            try {
              // Download the PDF file
              setCurrentProgress("Downloading original PDF...");
              await RNFS.downloadFile({ 
                fromUrl: url, 
                toFile: pdfPath,
                progress: (res) => {
                  // Show download progress
                  const progressPercent = res.bytesWritten / res.contentLength;
                  setCurrentProgress(`Downloading original PDF: ${Math.round(progressPercent * 100)}%`);
                }
              }).promise;
              
              setCurrentProgress("Preparing to split PDF...");
              
              // Read the PDF file - use a streaming approach for large files
              const pdfData = await RNFS.readFile(pdfPath, 'base64');
              
              try {
                // Load PDF document
                setCurrentProgress("Loading PDF document...");
                const pdfDoc = await PDFDocument.load(pdfData, {
                  // Add options to handle potential issues with corrupt PDFs
                  ignoreEncryption: true,
                  throwOnInvalidObject: false
                });
                
                const totalPages = pdfDoc.getPageCount();
                
                // Validate page numbers
                const validPageNumbers = splitPageNumbers.filter(pageNum => 
                  pageNum > 0 && pageNum <= totalPages
                );
                
                if (validPageNumbers.length === 0) {
                  throw new Error(`Invalid page numbers. The PDF has ${totalPages} pages.`);
                }
                
                // Create a new PDF document
                setCurrentProgress("Creating new PDF with selected pages...");
                const newPdfDoc = await PDFDocument.create();
                
                // Process pages in batches to improve memory usage for large PDFs
                const BATCH_SIZE = 5;
                for (let i = 0; i < validPageNumbers.length; i += BATCH_SIZE) {
                  const currentBatch = validPageNumbers.slice(i, i + BATCH_SIZE);
                  setCurrentProgress(`Processing pages ${i+1} to ${Math.min(i+BATCH_SIZE, validPageNumbers.length)} of ${validPageNumbers.length}...`);
                  
                  // Copy pages in current batch
                  for (const pageNumber of currentBatch) {
                    try {
                      const copiedPages = await newPdfDoc.copyPages(pdfDoc, [pageNumber - 1]);
                      newPdfDoc.addPage(copiedPages[0]);
                    } catch (pageError) {
                      console.error(`Error copying page ${pageNumber}:`, pageError);
                      setCurrentProgress(`Warning: Couldn't copy page ${pageNumber}, skipping...`);
                      // Continue with other pages even if one fails
                    }
                  }
                }
                
                // Save the new PDF
                setCurrentProgress("Generating final PDF...");
                const newPdfBytes = await newPdfDoc.save();
                const fileContent = newPdfBytes;
                
                // Upload to S3 with progress tracking
                setCurrentProgress("Uploading to cloud storage...");
                const uploadParams = {
                  Bucket: 'academic-ally',
                  Key: outputPath,
                  Body: fileContent,
                };
                
                try {
                  const upload = this.s3.upload(uploadParams);
                  
                  // Add upload progress tracking
                  upload.on('httpUploadProgress', (progress) => {
                    const percentage = Math.round((progress.loaded / progress.total) * 100);
                    setCurrentProgress(`Uploading to cloud: ${percentage}%`);
                  });
                  
                  await upload.promise();
                  setCurrentProgress("Cloud upload complete, processing PDF...");
                } catch (s3Error) {
                  console.error("S3 upload error:", s3Error);
                  setCurrentProgress("Cloud upload encountered an issue, but trying to continue...");
                  // Continue despite S3 error as the file might have been uploaded partially
                }
                
                // Process the uploaded PDF with retry logic
                setCurrentProgress("Preparing for analysis...");
                return await uploadWithRetry();
                
              } catch (pdfError) {
                console.error("PDF processing error:", pdfError);
                setCurrentProgress("Error processing the PDF file. Please try again.");
                throw new Error("Failed to process PDF: " + (pdfError.message || "Unknown error"));
              }
            } catch (downloadError) {
              console.error("Download error:", downloadError);
              setCurrentProgress("Error downloading the PDF file. Please check your connection.");
              throw new Error("Failed to download PDF: " + (downloadError.message || "Unknown error"));
            }
          }
        } catch (error) {
          console.error('Error while splitting and saving PDF:', error);
          // Show more detailed error message to the user
          setCurrentProgress(`Error: ${error.message || 'Failed to process PDF'}`);
          setStartedProcessing(false);
          
          // If it's a server error, suggest checking internet connection
          if (error.message && error.message.includes('500')) {
            setCurrentProgress('Server error. Please check your internet connection and try again later.');
          }
          
          return false;
        } finally {
          // Cleanup: remove temporary files
          try {
            if (await RNFS.exists(pdfPath)) {
              await RNFS.unlink(pdfPath);
            }
          } catch (cleanupError) {
            console.error("Failed to clean up temporary files:", cleanupError);
          }
        }
    };
      
    static uploadFileAndProcessPdf = async (fileUrl, outputPath, uid, notesData, uniqueId, splitPageNumbers, setCurrentProgress, setStartedProcessing) => {
      try {
        setCurrentProgress('Processing...');
        // Use a stable API URL instead of ngrok (which is temporary)
        // If you have a stable API URL, replace this
        // Updated the API URL with the new active ngrok URL
        const API_URL = 'https://academicallyapp.netlify.app/.netlify/functions/chat/initiate';
        
        // Call the backend API with proper POST method and headers
        const response = await fetch(API_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({
            userId: uid,
            fileUrl: fileUrl
          }),
          // Add a timeout to prevent indefinite hanging
          timeout: 30000 // 30 seconds timeout
        });
    
        // Get response as text first to handle both JSON and non-JSON responses safely
        const responseText = await response.text();
        
        if (!response.ok) {
          console.error(`HTTP error: ${response.status}`);
          console.error(`Response: ${responseText.substring(0, 200)}`);
          
          // For 502/504 errors, it might be a server timeout
          if (response.status === 502 || response.status === 504) {
            throw new Error(`Server timeout. The PDF might be too large or the server is busy.`);
          }
          
          try {
            const errorData = JSON.parse(responseText);
            throw new Error(errorData.message || `API error: ${response.status}`);
          } catch (parseError) {
            // If response is not valid JSON (e.g., HTML error page)
            if (responseText.includes('<html') || responseText.includes('<!DOCTYPE')) {
              throw new Error(`Server returned HTML instead of JSON. Status: ${response.status}`);
            } else {
              throw new Error(`Server returned an invalid response. Status: ${response.status}`);
            }
          }
        }
    
        // Parse JSON response safely
        let data;
        try {
          data = JSON.parse(responseText);
        } catch (jsonError) {
          console.error("JSON parse error:", jsonError);
          console.error("Response text:", responseText.substring(0, 100));
          throw new Error("Failed to parse server response");
        }
        
        setCurrentProgress('Initiating chat...');
    
        if (!data?.sourceId) {
          return { ...data, docId: `${notesData.id}_${uniqueId}` };
        }
    
        // Create document data with defaults
        const docData = {
          Year: '',
          branch: notesData?.branch || '',
          sem: notesData?.sem || '',
          university: notesData?.university || '',
          course: notesData?.course || '',
          subject: notesData?.subject || '',
          sourceId: data.sourceId,
          category: notesData?.category || '',
          name: notesData?.name || 'Untitled Document',
          uniqueId,
          date: new Date(),
          pages: Array.isArray(splitPageNumbers) ? splitPageNumbers : [],
          url: outputPath,
          conversation: [],
          docId: notesData.id
        };
    
        // Create document reference
        const docRef = firestoreDB()
          .collection('Users')
          .doc(uid)
          .collection('InitializedPdf')
          .doc(`${notesData.id}_${uniqueId}`);
    
        await docRef.set(docData);
        
        return { ...data, docId: `${notesData.id}_${uniqueId}` };
    
      } catch (error) {
        console.error('Processing error:', error);
        setCurrentProgress(`Error: ${error.message || 'Unknown error processing PDF'}`);
        
        // Log to crash reporting
        try {
          CrashlyticsService.recordError(error);
        } catch (crashError) {
          console.error("Failed to log to crash reporting:", crashError);
        }
        
        throw error; // Propagate error for handling in UI
      } finally {
        setStartedProcessing(false);
        setCurrentProgress('');
      }
    };

    static chatWithPdf = async (docId, message, uid) => {
        const body = {
          userId: uid,
          docId: docId,
          date: new Date(),
          message: message
        };
        console.log(body)
      
        const config = {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify(body)
        };
      
        return new Promise(async (resolve, reject) => {
          try {
            const response = await fetch(
              "https://academicallyapp.netlify.app/.netlify/functions/chat/message",
              config
            );
            
            if (!response.ok) {

              CrashlyticsService.setUserId(getCurrentUser()?.uid)
              resolve(false)
              // throw new Error(`HTTP error! Status: ${response.status}`);
            }
      
            const data = await response;
            resolve(data);
          } catch (error) {
            reject({ message: `Error: ${error.message}` });
          }
        });
      };
    static monitorMessageUpdates = async (chatId, setMessages, uid) => {
      const chatRef = firestoreDB().collection('Users').doc(uid).collection('InitializedPdf').doc(chatId);
    
      const unsubscribe = chatRef.onSnapshot((snapshot) => {
        const chatData = snapshot?.data();
        const messages = chatData ? chatData?.conversation : [];
        setMessages(messages);
      });
    
      // Return the unsubscribe function to stop listening
      return unsubscribe;
    };      
    
    static getChatDoc = async (uid, docId) => {
      try {
        const docRef = firestoreDB()
          .collection('Users')
          .doc(uid)
          .collection('InitializedPdf')
          .doc(docId);
          
        const docSnapshot = await docRef.get();
    
        if (docSnapshot?.exists) {
          const data = docSnapshot?.data();
          return data;
        } else {
          return { message: 'Document not found' };
        }
      } catch (error) {
        console.error(error);
        return { message: 'Error retrieving document' };
      }
    };    

    static canPDFBeAnalyzed(pdfSizeKB, numPages) {
      const minTextSizePerPageKB = 30;
      const maxTextSizePerPageKB = 200;
      const minEstimatedPDFSizeKB = minTextSizePerPageKB * numPages;
      const maxEstimatedPDFSizeKB = maxTextSizePerPageKB * numPages;
      if (pdfSizeKB <= maxEstimatedPDFSizeKB) {
          return true;
      } else {
          return false;
      }
  }
  
}

export default PdfViewerAction;