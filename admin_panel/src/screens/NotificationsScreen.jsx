import React, { useState } from "react";
import { motion } from "framer-motion";
import { FiSend, FiChevronDown } from "react-icons/fi";

const NotificationsScreen = () => {
  const [formData, setFormData] = useState({
    audience: "all",
    template: "",
    message: "",
  });
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  const audienceOptions = [
    { value: "all", label: "All Users" },
    { value: "teachers", label: "Teachers Only" },
    { value: "students", label: "Students Only" },
    { value: "specific", label: "Specific User ID" },
  ];

  const templateOptions = [
    { value: "", label: "Custom Message" },
    { value: "payout_processed", label: "Payout Processed" },
    { value: "test_scheduled", label: "Test Scheduled" },
    { value: "system_update", label: "System Update" },
  ];

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setSending(true);
    
    // Simulate API call
    setTimeout(() => {
      setSending(false);
      setSent(true);
      setFormData({
        audience: "all",
        template: "",
        message: "",
      });
      
      // Reset success message after 3 seconds
      setTimeout(() => setSent(false), 3000);
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-4xl mx-auto"
      >
        <h1 className="text-2xl font-bold text-gray-800 mb-2">Send Notifications</h1>
        <p className="text-gray-600 mb-6">Send FCM messages to students/teachers</p>
        
        {sent && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-6"
          >
            Notification sent successfully!
          </motion.div>
        )}
        
        <div className="bg-white rounded-xl shadow p-6">
          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Audience</label>
                <div className="relative">
                  <select
                    name="audience"
                    value={formData.audience}
                    onChange={handleChange}
                    className="w-full pl-3 pr-10 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 appearance-none"
                  >
                    {audienceOptions.map(option => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                  <FiChevronDown className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Template</label>
                <div className="relative">
                  <select
                    name="template"
                    value={formData.template}
                    onChange={handleChange}
                    className="w-full pl-3 pr-10 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 appearance-none"
                  >
                    {templateOptions.map(option => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                  <FiChevronDown className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>
            </div>
            
            {formData.audience === "specific" && (
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-1">User ID</label>
                <input
                  type="text"
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="Enter user ID"
                />
              </div>
            )}
            
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
              <textarea
                name="message"
                value={formData.message}
                onChange={handleChange}
                rows="4"
                className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Enter your notification message here..."
                required
              ></textarea>
            </div>
            
            <div className="flex justify-end">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                type="submit"
                disabled={sending}
                className={`px-6 py-3 rounded-lg text-white font-medium flex items-center ${
                  sending 
                    ? "bg-gray-400" 
                    : "bg-gradient-to-r from-indigo-600 to-purple-600 hover:opacity-90"
                } transition-all shadow-md`}
              >
                {sending ? (
                  "Sending..."
                ) : (
                  <>
                    <FiSend className="mr-2" /> Send Notification
                  </>
                )}
              </motion.button>
            </div>
          </form>
        </div>
        
        <div className="mt-8 bg-white rounded-xl shadow p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Message Templates</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-gray-200 rounded-lg p-4 hover:border-indigo-300 transition">
              <h3 className="font-medium text-gray-800 mb-1">Payout Processed</h3>
              <p className="text-sm text-gray-600">Your recent payout of ₹X has been successfully processed.</p>
            </div>
            <div className="border border-gray-200 rounded-lg p-4 hover:border-indigo-300 transition">
              <h3 className="font-medium text-gray-800 mb-1">Test Scheduled</h3>
              <p className="text-sm text-gray-600">New test "{`{test_name}`}" scheduled on {`{date}`} at {`{time}`}.</p>
            </div>
            <div className="border border-gray-200 rounded-lg p-4 hover:border-indigo-300 transition">
              <h3 className="font-medium text-gray-800 mb-1">System Update</h3>
              <p className="text-sm text-gray-600">We've released new features! Update your app to version X to access them.</p>
            </div>
            <div className="border border-gray-200 rounded-lg p-4 hover:border-indigo-300 transition">
              <h3 className="font-medium text-gray-800 mb-1">Test Results</h3>
              <p className="text-sm text-gray-600">Your results for "{`{test_name}`}" are now available. Check your dashboard.</p>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default NotificationsScreen;