import React, { useState } from "react";
import { motion } from "framer-motion";
import { FiUser, FiMail, FiLock, FiSave, FiEdit, FiCamera } from "react-icons/fi";

const AdminProfileScreen = () => {
  const [editMode, setEditMode] = useState(false);
  const [adminData, setAdminData] = useState({
    name: "Admin User",
    email: "admin@example.com",
    role: "Super Administrator",
    phone: "+91 9876543210",
    joined: "Jan 15, 2023"
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setAdminData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setEditMode(false);
    // In a real app, you would save the data to your backend
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-4 md:p-6">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200">Admin Profile</h1>
          <button
            onClick={() => setEditMode(!editMode)}
            className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition"
          >
            {editMode ? <FiSave className="text-lg" /> : <FiEdit className="text-lg" />}
            {editMode ? "Save Changes" : "Edit Profile"}
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-1">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow p-6">
              <div className="flex flex-col items-center">
                <div className="relative mb-4">
                  <div className="bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 rounded-full w-24 h-24 flex items-center justify-center text-3xl font-bold">
                    {adminData.name.charAt(0)}
                  </div>
                  {editMode && (
                    <button className="absolute bottom-0 right-0 bg-white dark:bg-gray-700 p-2 rounded-full shadow-md">
                      <FiCamera className="text-gray-700 dark:text-gray-300" />
                    </button>
                  )}
                </div>
                
                <h2 className="text-xl font-bold text-gray-800 dark:text-gray-200 mb-1">
                  {adminData.name}
                </h2>
                <p className="text-gray-600 dark:text-gray-400 mb-4">{adminData.role}</p>
                
                <div className="w-full mt-6">
                  <h3 className="font-medium text-gray-700 dark:text-gray-300 mb-3">Security</h3>
                  <button className="w-full flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition">
                    <span className="flex items-center gap-2">
                      <FiLock className="text-gray-700 dark:text-gray-300" />
                      Change Password
                    </span>
                    <span className="bg-indigo-100 dark:bg-indigo-900/50 text-indigo-800 dark:text-indigo-300 text-xs px-2 py-1 rounded">
                      Recommended
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <div className="lg:col-span-2">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow p-6">
              <h2 className="text-xl font-bold text-gray-800 dark:text-gray-200 mb-6">Profile Information</h2>
              
              <form onSubmit={handleSubmit}>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Full Name
                    </label>
                    {editMode ? (
                      <input
                        type="text"
                        name="name"
                        value={adminData.name}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200"
                        required
                      />
                    ) : (
                      <p className="px-4 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-800 dark:text-gray-200">
                        {adminData.name}
                      </p>
                    )}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Email Address
                    </label>
                    {editMode ? (
                      <input
                        type="email"
                        name="email"
                        value={adminData.email}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200"
                        required
                      />
                    ) : (
                      <p className="px-4 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-800 dark:text-gray-200">
                        {adminData.email}
                      </p>
                    )}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Phone Number
                    </label>
                    {editMode ? (
                      <input
                        type="tel"
                        name="phone"
                        value={adminData.phone}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200"
                      />
                    ) : (
                      <p className="px-4 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-800 dark:text-gray-200">
                        {adminData.phone || "Not provided"}
                      </p>
                    )}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Role
                    </label>
                    <p className="px-4 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-800 dark:text-gray-200">
                      {adminData.role}
                    </p>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Joined Date
                    </label>
                    <p className="px-4 py-2 bg-gray-50 dark:bg-gray-700 rounded-lg text-gray-800 dark:text-gray-200">
                      {adminData.joined}
                    </p>
                  </div>
                </div>
                
                {editMode && (
                  <div className="mt-8 flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={() => setEditMode(false)}
                      className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition"
                    >
                      Save Changes
                    </button>
                  </div>
                )}
              </form>
            </div>
            
            <div className="mt-6 bg-white dark:bg-gray-800 rounded-xl shadow p-6">
              <h2 className="text-xl font-bold text-gray-800 dark:text-gray-200 mb-6">Security Settings</h2>
              
              <div className="space-y-4">
                <div className="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <div>
                    <h3 className="font-medium text-gray-800 dark:text-gray-200">Two-Factor Authentication</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Add an extra layer of security to your account
                    </p>
                  </div>
                  <button className="px-4 py-2 bg-gray-200 dark:bg-gray-600 hover:bg-gray-300 dark:hover:bg-gray-500 text-gray-800 dark:text-gray-200 rounded-lg text-sm transition">
                    Enable
                  </button>
                </div>
                
                <div className="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <div>
                    <h3 className="font-medium text-gray-800 dark:text-gray-200">Login Activity</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Last login: Today at 10:30 AM from Chrome on Windows
                    </p>
                  </div>
                  <button className="px-4 py-2 text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300 text-sm transition">
                    View All
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminProfileScreen;