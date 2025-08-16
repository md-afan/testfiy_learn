import React, { useEffect, useState } from "react";
import { db } from "../services/firebase";
import { collection, query, where, getDocs, doc, updateDoc } from "firebase/firestore";
import { motion } from "framer-motion";
import { FiSearch, FiUserCheck, FiUserX, FiEye, FiX, FiMail, FiPhone, FiMapPin, FiUser } from "react-icons/fi"; // Added FiUser import

const TeacherRequestsScreen = () => {
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedTeacher, setSelectedTeacher] = useState(null);
  const [actionType, setActionType] = useState("");
  const [viewDetails, setViewDetails] = useState(false);

  const fetchPendingTeachers = async () => {
    setLoading(true);
    try {
      // Mock data
      const mockTeachers = [
        {
          id: "1",
          name: "John Smith",
          email: "john@example.com",
          phone: "9876543210",
          coachingName: "ABC Coaching",
          coachingAddress: "123 Main St, City",
          ownerPhotoUrl: "",
          coachingPhotoUrl: "",
          subjects: ["Mathematics", "Physics"],
          experience: "5 years",
          qualifications: "M.Sc in Physics, B.Ed",
          createdAt: "2023-10-15"
        },
        {
          id: "2",
          name: "Sarah Johnson",
          email: "sarah@example.com",
          phone: "9876543211",
          coachingName: "XYZ Institute",
          coachingAddress: "456 Park Ave, Town",
          ownerPhotoUrl: "",
          coachingPhotoUrl: "",
          subjects: ["Chemistry", "Biology"],
          experience: "8 years",
          qualifications: "Ph.D in Chemistry, M.Ed",
          createdAt: "2023-10-10"
        }
      ];
      setTeachers(mockTeachers);
    } catch (error) {
      console.error("Error fetching teachers:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (id, approved) => {
    console.log(`Teacher ${id} ${approved ? "approved" : "rejected"}`);
    fetchPendingTeachers();
    setSelectedTeacher(null);
  };

  useEffect(() => {
    fetchPendingTeachers();
  }, []);

  const filteredTeachers = teachers.filter(teacher => 
    teacher.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    teacher.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-4 md:p-6 w-full">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-7xl mx-auto"
      >
        <div className="flex flex-col md:flex-row md:items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200 mb-4 md:mb-0">Teacher Requests</h1>
          
          <div className="relative">
            <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search teachers..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 w-full md:w-80 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200"
            />
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Teacher</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Contact</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Coaching</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Images</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {loading ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-4 text-center text-gray-500 dark:text-gray-400">
                      <div className="flex justify-center">
                        <div className="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-indigo-500"></div>
                      </div>
                    </td>
                  </tr>
                ) : filteredTeachers.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-4 text-center text-gray-500 dark:text-gray-400">
                      No pending requests
                    </td>
                  </tr>
                ) : (
                  filteredTeachers.map((teacher) => (
                    <motion.tr 
                      key={teacher.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      whileHover={{ backgroundColor: "#f9fafb" }}
                      className="transition-colors dark:hover:bg-gray-700/50"
                    >
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="bg-gray-200 dark:bg-gray-700 border-2 border-dashed rounded-xl w-10 h-10" />
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900 dark:text-gray-200">{teacher.name}</div>
                            <div className="text-sm text-gray-500 dark:text-gray-400">{teacher.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900 dark:text-gray-200">{teacher.phone}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900 dark:text-gray-200">{teacher.coachingName}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">{teacher.coachingAddress}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex space-x-2">
                          <div className="bg-gray-200 dark:bg-gray-700 border-2 border-dashed rounded-xl w-10 h-10" />
                          <div className="bg-gray-200 dark:bg-gray-700 border-2 border-dashed rounded-xl w-10 h-10" />
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button
                            onClick={() => {
                              setSelectedTeacher(teacher);
                              setViewDetails(true);
                            }}
                            className="bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400 px-3 py-1 rounded-md flex items-center text-sm hover:bg-blue-200 dark:hover:bg-blue-900/50 transition"
                          >
                            <FiEye className="mr-1" /> View
                          </button>
                          <button
                            onClick={() => {
                              setSelectedTeacher(teacher);
                              setActionType("approve");
                            }}
                            className="bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 px-3 py-1 rounded-md flex items-center text-sm hover:bg-green-200 dark:hover:bg-green-900/50 transition"
                          >
                            <FiUserCheck className="mr-1" /> Approve
                          </button>
                          <button
                            onClick={() => {
                              setSelectedTeacher(teacher);
                              setActionType("reject");
                            }}
                            className="bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 px-3 py-1 rounded-md flex items-center text-sm hover:bg-red-200 dark:hover:bg-red-900/50 transition"
                          >
                            <FiUserX className="mr-1" /> Reject
                          </button>
                        </div>
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </motion.div>

      {/* View Details Modal */}
      {viewDetails && selectedTeacher && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 max-w-3xl w-full"
          >
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-xl font-bold text-gray-900 dark:text-gray-200">Teacher Details</h3>
              <button
                onClick={() => setViewDetails(false)}
                className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
              >
                <FiX className="h-6 w-6" />
              </button>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="md:col-span-1">
                <div className="bg-gray-200 dark:bg-gray-700 border-2 border-dashed rounded-xl w-full h-64 flex items-center justify-center">
                  <span className="text-gray-500 dark:text-gray-400">Owner Photo</span>
                </div>
                <div className="mt-4 bg-gray-200 dark:bg-gray-700 border-2 border-dashed rounded-xl w-full h-40 flex items-center justify-center">
                  <span className="text-gray-500 dark:text-gray-400">Coaching Photo</span>
                </div>
              </div>
              
              <div className="md:col-span-2">
                <div className="mb-6">
                  <h4 className="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-3">Personal Information</h4>
                  <div className="space-y-3">
                    <div className="flex items-center">
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg mr-3">
                        <FiUser className="text-gray-700 dark:text-gray-300" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Full Name</p>
                        <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.name}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center">
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg mr-3">
                        <FiMail className="text-gray-700 dark:text-gray-300" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Email Address</p>
                        <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.email}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center">
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg mr-3">
                        <FiPhone className="text-gray-700 dark:text-gray-300" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Phone Number</p>
                        <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.phone}</p>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="mb-6">
                  <h4 className="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-3">Coaching Information</h4>
                  <div className="space-y-3">
                    <div className="flex items-center">
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg mr-3">
                        <FiMapPin className="text-gray-700 dark:text-gray-300" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Coaching Name</p>
                        <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.coachingName}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center">
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg mr-3">
                        <FiMapPin className="text-gray-700 dark:text-gray-300" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Address</p>
                        <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.coachingAddress}</p>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="bg-gray-50 dark:bg-gray-700/50 p-4 rounded-lg">
                    <h5 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Subjects</h5>
                    <div className="flex flex-wrap gap-2">
                      {selectedTeacher.subjects.map((subject, index) => (
                        <span key={index} className="px-3 py-1 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-800 dark:text-indigo-300 rounded-full text-sm">
                          {subject}
                        </span>
                      ))}
                    </div>
                  </div>
                  
                  <div className="bg-gray-50 dark:bg-gray-700/50 p-4 rounded-lg">
                    <h5 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Experience</h5>
                    <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.experience}</p>
                  </div>
                  
                  <div className="bg-gray-50 dark:bg-gray-700/50 p-4 rounded-lg">
                    <h5 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Qualifications</h5>
                    <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.qualifications}</p>
                  </div>
                  
                  <div className="bg-gray-50 dark:bg-gray-700/50 p-4 rounded-lg">
                    <h5 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Request Date</h5>
                    <p className="font-medium text-gray-800 dark:text-gray-200">{selectedTeacher.createdAt}</p>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="flex justify-end gap-3 mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
              <button
                onClick={() => setViewDetails(false)}
                className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
              >
                Close
              </button>
              <button
                onClick={() => {
                  setViewDetails(false);
                  setSelectedTeacher(selectedTeacher);
                  setActionType("approve");
                }}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition"
              >
                Approve Request
              </button>
            </div>
          </motion.div>
        </div>
      )}

      {/* Confirmation Modal */}
      {selectedTeacher && actionType && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 max-w-md w-full"
          >
            <h3 className="text-lg font-medium text-gray-900 dark:text-gray-200 mb-4">
              {actionType === "approve" ? "Approve Teacher" : "Reject Teacher"}
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Are you sure you want to {actionType} <span className="font-semibold">{selectedTeacher.name}</span>?
              {actionType === "reject" && " This action cannot be undone."}
            </p>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => setSelectedTeacher(null)}
                className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition"
              >
                Cancel
              </button>
              <button
                onClick={() => handleUpdateStatus(selectedTeacher.id, actionType === "approve")}
                className={`px-4 py-2 rounded-md text-white ${
                  actionType === "approve" 
                    ? "bg-green-600 hover:bg-green-700" 
                    : "bg-red-600 hover:bg-red-700"
                } transition`}
              >
                {actionType === "approve" ? "Approve" : "Reject"}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
};

export default TeacherRequestsScreen;