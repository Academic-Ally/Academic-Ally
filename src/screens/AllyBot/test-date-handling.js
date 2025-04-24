// Test file for date handling in AllyBotActions.js
import React, { useEffect, useState } from 'react';
import { View, Text, Button, ScrollView } from 'react-native';
import AllyBotActions from './AllyBotActions';

// Mock for the firestoreDB function
const mockFirestoreDB = () => {
  return {
    collection: () => ({
      doc: () => ({
        collection: () => ({
          onSnapshot: (callback) => {
            // Simulate Firestore data with both valid and invalid date examples
            const mockSnapshot = {
              docs: [
                {
                  id: 'doc1',
                  data: () => ({
                    name: 'Document 1',
                    subject: 'Math',
                    // Valid Firestore timestamp
                    date: { 
                      seconds: 1622548800, 
                      nanoseconds: 0,
                      toDate: () => new Date(1622548800 * 1000)
                    },
                    conversations: [
                      { sender: 'User', message: 'Hello', date: new Date() }
                    ]
                  })
                },
                {
                  id: 'doc2',
                  data: () => ({
                    name: 'Document 2',
                    subject: 'Science',
                    // Invalid date - no toDate method
                    date: { 
                      seconds: 1622548800, 
                      nanoseconds: 0 
                    },
                    conversations: [
                      { sender: 'User', message: 'Test', date: new Date() }
                    ]
                  })
                },
                {
                  id: 'doc3',
                  data: () => ({
                    name: 'Document 3',
                    subject: 'English',
                    // Missing date
                    date: null,
                    conversations: []
                  })
                }
              ]
            };
            
            // Call the callback with mock data
            callback(mockSnapshot);
            
            // Return unsubscribe function
            return () => {};
          }
        })
      })
    })
  };
};

// Replace the real firestoreDB with our mock
jest.mock('../../Modules/auth/firebase/firebase', () => ({
  firestoreDB: mockFirestoreDB
}));

const DateHandlingTest = () => {
  const [documents, setDocuments] = useState([]);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    try {
      // This will call our mocked firestore
      const unsubscribe = AllyBotActions.loadInitiatedChats('test-uid')((docs) => {
        setDocuments(docs);
      });
      
      return unsubscribe;
    } catch (e) {
      setError(e.message);
    }
  }, []);
  
  return (
    <ScrollView style={{ padding: 20 }}>
      <Text style={{ fontSize: 20, fontWeight: 'bold', marginBottom: 20 }}>
        Date Handling Test
      </Text>
      
      {error && (
        <View style={{ padding: 10, backgroundColor: 'red', marginBottom: 10 }}>
          <Text style={{ color: 'white' }}>{error}</Text>
        </View>
      )}
      
      <Text style={{ marginBottom: 10 }}>
        Documents processed: {documents.length}
      </Text>
      
      {documents.map((doc, index) => (
        <View key={index} style={{ padding: 10, backgroundColor: '#f0f0f0', marginBottom: 10 }}>
          <Text>DocId: {doc.docId}</Text>
          <Text>Name: {doc.name}</Text>
          <Text>Subject: {doc.subject}</Text>
          <Text>Date: {doc.date ? doc.date.toString() : 'No date'}</Text>
          <Text>Last message: {doc.lastConversation?.message || 'No message'}</Text>
        </View>
      ))}
    </ScrollView>
  );
};

export default DateHandlingTest; 