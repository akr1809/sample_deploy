import React, { useState, useEffect } from 'react';
import UserForm from './components/UserForm';
import UserList from './components/UserList';
import { userAPI } from './services/api';

function App() {
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState(null);

  // Fetch users on component mount
  useEffect(() => {
    fetchUsers();
  }, []);

  // Auto-hide messages after 5 seconds
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => {
        setMessage(null);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [message]);

  const fetchUsers = async () => {
    try {
      setIsLoading(true);
      const response = await userAPI.getAllUsers();
      setUsers(response.data || []);
      setMessage(null);
    } catch (error) {
      console.error('Error fetching users:', error);
      setMessage({
        type: 'error',
        text: error.message || 'Failed to load users'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateUser = async (userData) => {
    try {
      setIsSubmitting(true);
      const response = await userAPI.createUser(userData);
      
      // Add new user to the list (prepend to show it first)
      setUsers(prevUsers => [response.data, ...prevUsers]);
      
      setMessage({
        type: 'success',
        text: 'User added successfully!'
      });
    } catch (error) {
      console.error('Error creating user:', error);
      setMessage({
        type: 'error',
        text: error.message || 'Failed to add user'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteUser = async (userId) => {
    try {
      await userAPI.deleteUser(userId);
      
      // Remove user from the list
      setUsers(prevUsers => prevUsers.filter(user => user._id !== userId));
      
      setMessage({
        type: 'success',
        text: 'User deleted successfully!'
      });
    } catch (error) {
      console.error('Error deleting user:', error);
      setMessage({
        type: 'error',
        text: error.message || 'Failed to delete user'
      });
    }
  };

  return (
    <div className="app">
      <div className="container">
        <header className="header">
          <h1>User Management</h1>
          <p>A modern full-stack application for managing users</p>
        </header>
        
        <main className="content">
          {message && (
            <div className={`message ${message.type}`}>
              {message.text}
            </div>
          )}
          
          <UserForm 
            onSubmit={handleCreateUser} 
            isLoading={isSubmitting} 
          />
          
          <UserList 
            users={users}
            onDelete={handleDeleteUser}
            isLoading={isLoading}
          />
        </main>
      </div>
    </div>
  );
}

export default App;