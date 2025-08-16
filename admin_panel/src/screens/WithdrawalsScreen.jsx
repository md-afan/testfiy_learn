import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";

const WithdrawalsScreen = () => {
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState("all");

  // Mock withdrawal data (assumes 'role' is present)
  const mockWithdrawals = [
    {
      id: "1",
      user: "student1@example.com",
      upiId: "student1@upi",
      amount: 1200,
      requestedAt: "2023-10-15",
      status: "approved",
      role: "student",
    },
    {
      id: "2",
      user: "teacher1@example.com",
      upiId: "teacher1@upi",
      amount: 2500,
      requestedAt: "2023-10-14",
      status: "approved",
      role: "teacher",
    },
    {
      id: "3",
      user: "admin@example.com",
      upiId: "admin@upi",
      amount: 3200,
      requestedAt: "2023-10-13",
      status: "approved",
      role: "admin",
    },
    {
      id: "4",
      user: "teacher2@example.com",
      upiId: "teacher2@upi",
      amount: 1500,
      requestedAt: "2023-10-12",
      status: "rejected",
      role: "teacher",
    },
  ];

  const fetchWithdrawals = async () => {
    setLoading(true);
    try {
      // Simulate API call
      setTimeout(() => {
        setWithdrawals(mockWithdrawals);
        setLoading(false);
      }, 600);
    } catch (error) {
      console.error("Error fetching withdrawals:", error);
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWithdrawals();
  }, []);

  const getStatusChip = (status) => {
    switch (status) {
      case "pending":
        return (
          <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs">
            Pending
          </span>
        );
      case "approved":
        return (
          <span className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs">
            Approved
          </span>
        );
      case "rejected":
        return (
          <span className="bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs">
            Rejected
          </span>
        );
      default:
        return (
          <span className="bg-gray-100 text-gray-800 px-2 py-1 rounded-full text-xs">
            {status}
          </span>
        );
    }
  };

  const filteredWithdrawals = withdrawals.filter((w) => {
    if (roleFilter === "all") return true;
    return w.role === roleFilter;
  });

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-7xl mx-auto"
      >
        <div className="flex flex-col md:flex-row md:items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-800 mb-4 md:mb-0">
            Withdrawal History
          </h1>
          <div className="flex items-center space-x-3">
            <div className="bg-white shadow rounded-lg px-4 py-2">
              <select
                value={roleFilter}
                onChange={(e) => setRoleFilter(e.target.value)}
                className="bg-transparent text-sm focus:outline-none"
              >
                <option value="all">All Roles</option>
                <option value="student">Students</option>
                <option value="teacher">Teachers</option>
                <option value="admin">Admins</option>
              </select>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    User
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    UPI ID
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Amount
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Request Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-4 text-center">
                      Loading withdrawals...
                    </td>
                  </tr>
                ) : filteredWithdrawals.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                      No withdrawals found for this filter
                    </td>
                  </tr>
                ) : (
                  filteredWithdrawals.map((w) => (
                    <motion.tr
                      key={w.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      whileHover={{ backgroundColor: "#f9fafb" }}
                      className="transition-colors"
                    >
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {w.user}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700 capitalize">
                        {w.role}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {w.upiId}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900">
                        ₹{w.amount}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {w.requestedAt}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getStatusChip(w.status)}
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default WithdrawalsScreen;
