import axios from 'axios';

const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? '/api' 
  : 'http://localhost:5000/api';

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    console.log(`🌐 ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    console.error('❌ Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    console.log(`✅ ${response.status} ${response.config.url}`);
    return response;
  },
  (error) => {
    const errorMessage = error.response?.data?.message || error.message || 'Network error';
    console.error('❌ Response Error:', errorMessage);
    return Promise.reject(error);
  }
);

// API methods
export const userAPI = {
  // Get all users
  getAllUsers: async () => {
    try {
      const response = await api.get('/users');
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Failed to fetch users');
    }
  },

  // Create a new user
  createUser: async (userData) => {
    try {
      const response = await api.post('/users', userData);
      return response.data;
    } catch (error) {
      if (error.response?.status === 400) {
        // Validation errors
        const errors = error.response.data.errors || [{ msg: error.response.data.message }];
        throw new Error(errors[0].msg);
      } else if (error.response?.status === 409) {
        // Conflict (user already exists)
        throw new Error(error.response.data.message);
      }
      throw new Error(error.response?.data?.message || 'Failed to create user');
    }
  },

  // Delete a user
  deleteUser: async (userId) => {
    try {
      const response = await api.delete(`/users/${userId}`);
      return response.data;
    } catch (error) {
      if (error.response?.status === 404) {
        throw new Error('User not found');
      }
      throw new Error(error.response?.data?.message || 'Failed to delete user');
    }
  },

  // Update a user
  updateUser: async (userId, userData) => {
    try {
      const response = await api.put(`/users/${userId}`, userData);
      return response.data;
    } catch (error) {
      if (error.response?.status === 400) {
        const errors = error.response.data.errors || [{ msg: error.response.data.message }];
        throw new Error(errors[0].msg);
      } else if (error.response?.status === 404) {
        throw new Error('User not found');
      } else if (error.response?.status === 409) {
        throw new Error(error.response.data.message);
      }
      throw new Error(error.response?.data?.message || 'Failed to update user');
    }
  },

  // Health check
  healthCheck: async () => {
    try {
      const response = await api.get('/health');
      return response.data;
    } catch (error) {
      throw new Error('Backend server is not responding');
    }
  }
};

export default api;