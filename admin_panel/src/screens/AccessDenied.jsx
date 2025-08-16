import React from "react";
import { motion } from "framer-motion";
import { FiLock } from "react-icons/fi";
import { Link } from "react-router-dom";

const AccessDenied = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full text-center"
      >
        <div className="flex justify-center mb-6">
          <div className="bg-red-100 text-red-600 w-16 h-16 rounded-full flex items-center justify-center">
            <FiLock className="text-2xl" />
          </div>
        </div>
        
        <h2 className="text-2xl font-bold text-gray-800 mb-2">Access Denied</h2>
        <p className="text-gray-600 mb-6">
          You don't have permission to access this page. Please contact your administrator.
        </p>
        
        <Link
          to="/login"
          className="inline-block bg-indigo-600 text-white py-2.5 px-6 rounded-lg hover:bg-indigo-700 transition"
        >
          Return to Login
        </Link>
      </motion.div>
    </div>
  );
};

export default AccessDenied;