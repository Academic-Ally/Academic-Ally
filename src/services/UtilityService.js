import dynamicLinks from '@react-native-firebase/dynamic-links';
import queryString from 'query-string';
import PermissionService from './PermissionService';
import { Platform, ToastAndroid, Alert } from 'react-native';
import RNFS from 'react-native-fs';

class UtilityService {

    static months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "June",
        "July",
        "Aug",
        "Sept",
        "Oct",
        "Nov",
        "Dec",
    ];
    static days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

    static checkEmpty(obj) {
        if (obj === undefined || obj === null) {
            return true;
        }
        if (Array.isArray(obj) && obj.length === 0) {
            return true;
        }
        if (typeof obj === 'object' && Object.keys(obj).length === 0) {
            return true;
        }
        if (typeof obj === "string" || typeof obj === "number") {
            return obj.toString().trim().length === 0;
        }
        for (let key in obj) {
            if (hasOwnProperty.call(obj, key)) {
                return false;
            }
        }
        return true;
    }

    static roundOffValue(value, precision) {
        let multiplier = Math.pow(10, precision || 0);
        return Math.round(Number(value) * multiplier) / multiplier;
    }

    static getJSON(data) {
        let result = {};
        try {
            if (!UtilityService.checkEmpty(data)) {
                result = JSON.parse(data);
            }
            return result;
        } catch (e) {
            return result;
        }
    }

    static getMonthNameFromIndex(index) {
        if (index === undefined || index === null || 
            !Array.isArray(UtilityService.months) || 
            index < 0 || 
            index >= UtilityService.months.length) {
            return '';
        }
        return UtilityService.months[index];
    }

    static formatDateFromTimestamp(timestamp, format) {
        if (timestamp == null || format == null) {
            return '';
        }
        try {
            const time = new Date(timestamp * 1000);
            if (isNaN(time.getTime())) {
                return '';
            }
            
            const yyyy = time.getFullYear();
            let yy = '';
            try {
                yy = yyyy.toString().substring(2);
            } catch (e) {
                yy = '';
            }
            
            let MM = time.getMonth() + 1;
            let dd = time.getDate();
            let hh = time.getHours();
            let mm = time.getMinutes();
            let ss = time.getSeconds();
            let DD = time.getDay();
            const A = hh < 12 ? "AM" : "PM";

            if (format.indexOf("A") > -1) {
                hh = hh > 12 ? hh - 12 : hh;
                hh = hh === 0 ? 12 : hh;
            }

            MM = MM < 10 ? "0" + MM : MM;
            dd = dd < 10 ? "0" + dd : dd;
            hh = hh < 10 ? "0" + hh : hh;
            mm = mm < 10 ? "0" + mm : mm;

            let formattedDate = format;
            formattedDate = formattedDate.replace("A", A);
            formattedDate = formattedDate.replace("yyyy", yyyy);
            formattedDate = formattedDate.replace("yy", yy);
            
            const monthsArray = Array.isArray(UtilityService.months) ? UtilityService.months : [];
            const monthName = (MM - 1 >= 0 && MM - 1 < monthsArray.length) ? monthsArray[MM - 1] : '';
            formattedDate = formattedDate.replace("MMM", monthName);
            formattedDate = formattedDate.replace("MM", MM);
            formattedDate = formattedDate.replace("dd", dd);
            formattedDate = formattedDate.replace("hh", hh);
            formattedDate = formattedDate.replace("mm", mm);
            formattedDate = formattedDate.replace("ss", ss);
            
            const daysArray = Array.isArray(UtilityService.days) ? UtilityService.days : [];
            const day = (DD >= 0 && DD < daysArray.length) ? daysArray[DD] : '';
            const dayAbbr = day && typeof day === 'string' && day.length >= 3 ? day.substring(0, 3) : '';
            formattedDate = formattedDate.replace("DDD", dayAbbr);
            formattedDate = formattedDate.replace("DD", day);

            return formattedDate;
        } catch (error) {
            console.error('Error formatting date from timestamp:', error);
            return '';
        }
    }

    static formatDate(date, format) {
        if (!date || !format) {
            return '';
        }
        
        try {
            const time = new Date(date);
            if (isNaN(time.getTime())) {
                return '';
            }
            
            const yyyy = time.getFullYear();
            const yy = yyyy % 100;
            let MM = time.getMonth() + 1;
            let dd = time.getDate();
            let hh = time.getHours();
            let mm = time.getMinutes();
            let ss = time.getSeconds();
            let DD = time.getDay();
            const A = hh < 12 ? "AM" : "PM";
            
            let hour = hh;
            if (format.indexOf("A") > -1) {
                hour = hh > 12 ? hh - 12 : hh;
                // Fix for midnight (12 AM)
                hour = hour === 0 ? 12 : hour;
            }
            
            MM = MM < 10 ? "0" + MM : MM;
            dd = dd < 10 ? "0" + dd : dd;
            hour = hour < 10 ? "0" + hour : hour;
            mm = mm < 10 ? "0" + mm : mm;
            
            let formattedDate = format;
            formattedDate = formattedDate.replace("A", A);
            formattedDate = formattedDate.replace("yyyy", yyyy);
            formattedDate = formattedDate.replace("yy", yy);
            
            const monthsArray = Array.isArray(UtilityService.months) ? UtilityService.months : [];
            const monthIdx = MM - 1;
            const monthName = (monthIdx >= 0 && monthIdx < monthsArray.length) ? monthsArray[monthIdx] : '';
            
            formattedDate = formattedDate.replace("MMMM", monthName);
            const monthAbbr = monthName && typeof monthName === 'string' && monthName.length >= 3 ? 
                monthName.substring(0, 3) : '';
            formattedDate = formattedDate.replace("MMM", monthAbbr);
            formattedDate = formattedDate.replace("MM", MM);
            formattedDate = formattedDate.replace("dd", dd);
            formattedDate = formattedDate.replace("hh", hour);
            formattedDate = formattedDate.replace("mm", mm);
            formattedDate = formattedDate.replace("ss", ss);
            
            const daysArray = Array.isArray(UtilityService.days) ? UtilityService.days : [];
            const day = (DD >= 0 && DD < daysArray.length) ? daysArray[DD] : '';
            const dayAbbr = day && typeof day === 'string' && day.length >= 3 ? 
                day.substring(0, 3) : '';
            
            formattedDate = formattedDate.replace("DDD", dayAbbr);
            formattedDate = formattedDate.replace("DD", day);
            
            return formattedDate;
        } catch (error) {
            console.error('Error formatting date:', error);
            return '';
        }
    }

    static isFloat(n) {
        return Number(n) === n && n % 1 !== 0;
    }

    static isInt(n) {
        return n % 1 === 0;
    }

    static isTrue(data) {
        return data === "true" || data === true;
    }

    static isFalse(data) {
        return data === "false" || data === false;
    }

    static isNumeric(str) {
        if (typeof str !== "string") {
            return false;
        } // we only process strings!
        return (
            !isNaN(str) && // use type coercion to parse the _entirety_ of the string (`parseFloat` alone does not do this)...
            !isNaN(parseFloat(str))
        ); // ...and ensure strings of whitespace fail
    }

    static getDayDiffInMinutes(date1, date2) {
        if (!date1 || !date2) {
            return 0;
        }
        try {
            const diff = Math.abs(new Date(date1) - new Date(date2));
            return Math.floor((diff / 1000) / 60);
        } catch (error) {
            return 0;
        }
    }

    static getDayDiffInHoursMinSec(date1, date2) {
        if (!date1 || !date2) {
            return { h: 0, m: 0, s: 0 };
        }
        try {
            const minutes = this.getDayDiffInMinutes(date1, date2);
            const h = parseInt(minutes / 60);
            const m = parseInt(minutes % 60);
            const s = (Math.abs(new Date(date1) - new Date(date2)) / 1000) % 60;
            return { h, m, s };
        } catch (error) {
            return { h: 0, m: 0, s: 0 };
        }
    }

    static getHHMMDayDiff(date1, date2) {
        if (!date1 || !date2) {
            return '0/0';
        }
        try {
            const minutes = UtilityService.getDayDiffInMinutes(date1, date2);
            return `${Math.floor(minutes / 60)}/${minutes % 60}`;
        } catch (error) {
            return '0/0';
        }
    }

    static getAttendanceStatusData(type) {
        const data = UtilityService.attendanceStatus?.[type];
        if (!UtilityService.checkEmpty(data)) {
            return data;
        }
        return {
            shortCode: "NA",
            textColor: "#D85B00",
            backGroundColor: "#FFC89F",
        };
    }

    static getDayFromDate(date) {
        if (!date) {
            return '';
        }
        try {
            const d = new Date(date);
            if (isNaN(d.getTime())) {
                return '';
            }
            
            const dayIndex = d.getDay();
            const daysArray = Array.isArray(UtilityService.days) ? UtilityService.days : [];
            const dayName = dayIndex >= 0 && dayIndex < daysArray.length ? daysArray[dayIndex] : '';
            
            if (!dayName || typeof dayName !== 'string' || dayName.length < 3) {
                return '';
            }
            
            return dayName.substring(0, 3).toUpperCase();
        } catch (error) {
            return '';
        }
    }

    static getLabelFromStatus(status) {
        if (!status || typeof status !== 'string') {
            return '';
        }
        return status.replace("_", " ");
    }

    static getNameInitials(name) {
        if (!name || typeof name !== 'string') {
            return '';
        }
        try {
            return name.split(" ")
                .map(function(part) { 
                    return part && typeof part === 'string' && part.length > 0 ? 
                        part.substring(0, 1) : '';
                })
                .filter(Boolean)
                .join("")
                .toUpperCase();
        } catch (error) {
            return '';
        }
    }

    static convertTo24HourFormat(dateString) {
        if (!dateString) {
            return '';
        }
        try {
            const date = new Date(dateString);
            if (isNaN(date.getTime())) {
                return '';
            }
            
            const hours = date.getHours().toString().padStart(2, '0');
            const minutes = date.getMinutes().toString().padStart(2, '0');
            const seconds = date.getSeconds().toString().padStart(2, '0');
            return `${hours}:${minutes}:${seconds}`;
        } catch (error) {
            return '';
        }
    }

    static removeString(str) {
        if (!str || typeof str !== 'string') {
            return '';
        }
        
        try {
            if (str.includes('(oufastupdates.com)') || str.includes('.pdf')) {
                const text = str.replace(/\(oufastupdates.com\)|\.pdf/g, '');
                return text.length > 35 ? text.substring(0, 35) + '...' : text;
            }
            
            if (str.length > 15) {
                return str.substring(0, 5) + '...';
            }
            
            return str;
        } catch (error) {
            return str;
        }
    }

    static replaceString(str, placeholdersValues) {
        if (!str || typeof str !== 'string' || !Array.isArray(placeholdersValues)) {
            return '';
        }
        
        try {
            const placeholders = ['${university}', '${course}', '${branch}', '${sem}', '${category}', '${name}', '${subject}', '${did}', '${uid}', '${uid2}', '${uid3}'];
            let replacedStr = str;

            for (const placeholder of placeholders) {
                if (replacedStr.includes(placeholder)) {
                    const index = placeholders.indexOf(placeholder);
                    if (index >= 0 && index < placeholdersValues.length) {
                        const value = placeholdersValues[index] || '';
                        replacedStr = replacedStr.replace(placeholder, value);
                    }
                }
            }
            return replacedStr;
        } catch (error) {
            return str;
        }
    }

    static replaceUnusualCharacters(str, character) {
        if (!str || typeof str !== 'string' || !character) {
            return str || '';
        }
        
        try {
            if (str.includes(character)) {
                return str.replace(character, '_');
            }
            return str;
        } catch (error) {
            return str;
        }
    }

    static getDynamicLinkData(link) {
        if (!link || !link.url) {
            return { userData: {}, notesData: {}, screen: '' };
        }
        
        try {
            const urlParts = link.url.split('?');
            if (urlParts.length < 2) {
                return { userData: {}, notesData: {}, screen: '' };
            }
            
            const query = urlParts[1];
            const parsedData = queryString.parse(query);
          
            const userData = {
              university: parsedData?.university || '',
              Course: parsedData?.course || '', // You can remove this line if 'Course' is not needed
              course: parsedData?.course || '',
              branch: parsedData?.branch || '',
              sem: parsedData?.sem || '',
            };
          
            const notesData = {
              course: parsedData?.course || '',
              branch: parsedData?.branch || '',
              sem: parsedData?.sem || '',
              subject: parsedData?.subject || '',
              category: parsedData?.category || '',
              did: parsedData?.did || '',
              name: parsedData?.name || '',
              units: parsedData?.units || '',
              university: parsedData?.university || '',
              id: parsedData?.id || '',
            };
            
            const screen = parsedData?.page || '';
            return { userData, notesData, screen };
        } catch (error) {
            console.error('Error parsing dynamic link data:', error);
            return { userData: {}, notesData: {}, screen: '' };
        }
    }

    static generateAbbreviation(subject) {
        if (!subject || typeof subject !== 'string') {
            return '';
        }
        
        try {
            const words = subject.split(' ');
            const excludedTerms = ['of', 'for', 'and'];
            const abbreviation = words
                .filter(word => word && typeof word === 'string' && !excludedTerms.includes(word.toLowerCase()))
                .map(word => word.charAt(0) || '')
                .filter(Boolean)
                .join('');
                
            return abbreviation.toLowerCase();
        } catch (error) {
            return '';
        }
    }

    static async generateLink(notesData, screen) {
        if (!notesData || !screen) {
            return '';
        }
        
        try {
            switch (screen) {
                case 'PdfViewer':
                    return `https://app.getacademically.co/${notesData?.category || ''}/${notesData?.university || ''}/${notesData?.course || ''}/${notesData?.branch || ''}/${notesData?.sem || ''}/${notesData?.subject || ''}/${notesData?.did || ''}/${notesData?.units || ''}/${notesData?.name || ''}/PdfViewer`;
                case 'SubjectResourcesScreen':
                    return `https://app.getacademically.co/Resources/${notesData?.university || ''}/${notesData?.course || ''}/${notesData?.branch || ''}/${notesData?.sem || ''}/${notesData?.subject || ''}/SubjectResourcesScreen`;
                case 'Resources':
                    return `https://app.getacademically.co/${notesData?.category || ''}/${notesData?.university || ''}/${notesData?.course || ''}/${notesData?.branch || ''}/${notesData?.sem || ''}/${notesData?.subject || ''}/${notesData?.did || ''}/${notesData?.units || ''}/${notesData?.name || ''}/Resources`;
                default:
                    return '';
            }
        } catch (error) {
            return '';
        }
    }

    static async generateDynamicLink(url, notesData, screen) {
        if (!url || !notesData) {
            return '';
        }
        
        try {
            const queryParams = new URLSearchParams({
                university: notesData.university || '',
                course: notesData.course || '',
                branch: notesData.branch || '',
                sem: notesData.sem || '',
                subject: notesData.subject || '',
                page: 'SubjectResources'
              });
              
            return dynamicLinks().buildShortLink(
                {
                    link: `https://app.getacademically.co?${queryParams}`,
                    domainUriPrefix: url,
                    android: {
                        packageName: 'com.academically',
                    },
                },
                dynamicLinks.ShortLinkType.SHORT,
            ).catch((error) => {
                console.error('Error generating dynamic link:', error);
                if (typeof Toast !== 'undefined' && Toast.show) {
                    Toast.show({
                        title: 'Something went wrong, Please try again later',
                        duration: 3000,
                    });
                }
                return '';
            });
        } catch (error) {
            console.error('Error in generateDynamicLink:', error);
            return '';
        }
    }

    /**
     * Request storage permission and handle the result
     * @param {Function} onSuccess - Callback function to execute if permission is granted
     * @param {Function} onFailure - Callback function to execute if permission is denied
     */
    static async requestStoragePermission(onSuccess, onFailure) {
        try {
            const hasPermission = await PermissionService.checkAndRequestStoragePermission();
            
            if (hasPermission) {
                if (typeof onSuccess === 'function') {
                    onSuccess();
                }
                return true;
            } else {
                if (typeof onFailure === 'function') {
                    onFailure();
                } else {
                    // Default failure handler
                    const message = 'Storage permission is required for this feature';
                    if (Platform.OS === 'android') {
                        ToastAndroid.show(message, ToastAndroid.LONG);
                    } else {
                        Alert.alert('Permission Required', message);
                    }
                }
                return false;
            }
        } catch (error) {
            console.error('Error in requestStoragePermission:', error);
            return false;
        }
    }

    /**
     * Save a file to device storage with permission handling
     * @param {string} fileUrl - URL of the file to download
     * @param {string} fileName - Name to save the file as
     * @param {string} mimeType - MIME type of the file
     * @returns {Promise<string|null>} - Path to the saved file or null if failed
     */
    static async saveFileToDevice(fileUrl, fileName, mimeType = 'application/pdf') {
        try {
            const permissionGranted = await UtilityService.requestStoragePermission();
            
            if (!permissionGranted) {
                return null;
            }
            
            // Determine download path based on platform
            const downloadPath = Platform.OS === 'ios'
                ? `${RNFS.DocumentDirectoryPath}/${fileName}`
                : `${RNFS.DownloadDirectoryPath}/${fileName}`;
            
            // Download the file
            const response = await RNFS.downloadFile({
                fromUrl: fileUrl,
                toFile: downloadPath,
                background: true,
                progressDivider: 10,
            }).promise;
            
            if (response.statusCode === 200) {
                // Show success message
                const message = `File saved to ${Platform.OS === 'ios' ? 'Documents' : 'Downloads'}`;
                if (Platform.OS === 'android') {
                    ToastAndroid.show(message, ToastAndroid.LONG);
                } else {
                    Alert.alert('Success', message);
                }
                
                return downloadPath;
            } else {
                // Show error message
                const errorMessage = 'Failed to download file';
                if (Platform.OS === 'android') {
                    ToastAndroid.show(errorMessage, ToastAndroid.LONG);
                } else {
                    Alert.alert('Error', errorMessage);
                }
                
                return null;
            }
        } catch (error) {
            console.error('Error saving file:', error);
            
            // Show error message
            const errorMessage = 'An error occurred while saving the file';
            if (Platform.OS === 'android') {
                ToastAndroid.show(errorMessage, ToastAndroid.LONG);
            } else {
                Alert.alert('Error', errorMessage);
            }
            
            return null;
        }
    }
}
export default UtilityService;
