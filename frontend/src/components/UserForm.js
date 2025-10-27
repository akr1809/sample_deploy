import React, { useState } from 'react';

const UserForm = ({ onSubmit, isLoading }) => {
  const [name, setName] = useState('');
  const [error, setError] = useState('');

  const validateName = (name) => {
    if (!name.trim()) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (name.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    if (!/^[a-zA-Z\s]+$/.test(name.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return '';
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    const validationError = validateName(name);
    if (validationError) {
      setError(validationError);
      return;
    }

    setError('');
    onSubmit({ name: name.trim() });
    setName('');
  };

  const handleNameChange = (e) => {
    const value = e.target.value;
    setName(value);
    
    // Clear error when user starts typing
    if (error) {
      setError('');
    }
  };

  return (
    <div className="form-section">
      <h2 className="section-title">Add New User</h2>
      <form onSubmit={handleSubmit} className="user-form">
        <div className="form-group">
          <label htmlFor="name" className="form-label">
            Full Name
          </label>
          <input
            type="text"
            id="name"
            value={name}
            onChange={handleNameChange}
            className={`form-input ${error ? 'error' : ''}`}
            placeholder="Enter your full name"
            disabled={isLoading}
            autoComplete="name"
          />
          {error && <span className="error-message">{error}</span>}
        </div>
        
        <button 
          type="submit" 
          className="submit-button"
          disabled={isLoading || !name.trim()}
        >
          {isLoading ? (
            <>
              <div className="spinner"></div>
              Adding User...
            </>
          ) : (
            'Add User'
          )}
        </button>
      </form>
    </div>
  );
};

export default UserForm;