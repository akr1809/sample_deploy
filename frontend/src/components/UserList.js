import React, { useState } from 'react';

const UserList = ({ users, onDelete, isLoading }) => {
  const [deletingId, setDeletingId] = useState(null);

  const handleDelete = async (userId) => {
    setDeletingId(userId);
    try {
      await onDelete(userId);
    } finally {
      setDeletingId(null);
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (isLoading) {
    return (
      <div className="users-section">
        <h2 className="section-title">Users List</h2>
        <div style={{ position: 'relative', minHeight: '200px' }}>
          <div className="loading-overlay">
            <div className="loading-text">
              <div className="spinner"></div>
              Loading users...
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="users-section">
      <h2 className="section-title">
        Users List {users.length > 0 && `(${users.length})`}
      </h2>
      
      {users.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">👥</div>
          <div className="empty-state-text">No users found</div>
          <div className="empty-state-subtext">
            Add your first user using the form above
          </div>
        </div>
      ) : (
        <div className="users-list">
          {users.map((user) => (
            <div key={user._id} className="user-card">
              <div className="user-info">
                <div className="user-name">{user.name}</div>
                <div className="user-date">
                  Added {formatDate(user.createdAt)}
                </div>
              </div>
              
              <button
                onClick={() => handleDelete(user._id)}
                className="delete-button"
                disabled={deletingId === user._id}
                title="Delete user"
              >
                {deletingId === user._id ? (
                  <>
                    <div className="spinner"></div>
                    Deleting...
                  </>
                ) : (
                  'Delete'
                )}
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default UserList;