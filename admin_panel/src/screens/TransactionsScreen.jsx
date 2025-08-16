import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { FiFilter, FiDownload } from "react-icons/fi";

const TransactionsScreen = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("all");
  const [filters, setFilters] = useState({
    type: "",
    status: "",
    dateRange: "",
  });

  // Mock transaction data
  const mockTransactions = [
    {
      id: "1",
      type: "test_fee",
      amount: 250,
      user: "student1@example.com",
      date: "2023-10-15",
      status: "completed",
    },
    {
      id: "2",
      type: "payout",
      amount: 180,
      user: "teacher1@example.com",
      date: "2023-10-14",
      status: "pending",
    },
    {
      id: "3",
      type: "commission",
      amount: 25,
      user: "system",
      date: "2023-10-13",
      status: "completed",
    },
    {
      id: "4",
      type: "test_fee",
      amount: 300,
      user: "student2@example.com",
      date: "2023-10-12",
      status: "completed",
    },
  ];

  const fetchTransactions = async () => {
    setLoading(true);
    try {
      // Simulate API call
      setTimeout(() => {
        setTransactions(mockTransactions);
        setLoading(false);
      }, 800);
    } catch (error) {
      console.error("Error fetching transactions:", error);
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, []);

  const filteredTransactions = transactions.filter(txn => {
    return (
      (activeTab === "all" || txn.type === activeTab) &&
      (filters.status === "" || txn.status === filters.status) &&
      (filters.dateRange === "" || txn.date >= filters.dateRange)
    );
  });

  const getTypeLabel = (type) => {
    switch (type) {
      case "test_fee": return "Test Fee";
      case "payout": return "Reward Payout";
      case "commission": return "App Commission";
      default: return type;
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case "completed": 
        return <span className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs">Completed</span>;
      case "pending": 
        return <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs">Pending</span>;
      case "failed": 
        return <span className="bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs">Failed</span>;
      default: 
        return <span className="bg-gray-100 text-gray-800 px-2 py-1 rounded-full text-xs">{status}</span>;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-7xl mx-auto"
      >
        <div className="flex flex-col md:flex-row md:items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-800 mb-4 md:mb-0">Transactions</h1>
          <div className="flex space-x-3">
            <button className="bg-white shadow rounded-lg px-4 py-2 flex items-center text-sm font-medium text-gray-700 hover:bg-gray-50 transition">
              <FiDownload className="mr-2" /> Export
            </button>
            <button className="bg-white shadow rounded-lg px-4 py-2 flex items-center text-sm font-medium text-gray-700 hover:bg-gray-50 transition">
              <FiFilter className="mr-2" /> Filters
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex border-b mb-6">
          <button
            className={`px-4 py-2 font-medium ${activeTab === "all" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-gray-500"}`}
            onClick={() => setActiveTab("all")}
          >
            All
          </button>
          <button
            className={`px-4 py-2 font-medium ${activeTab === "test_fee" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-gray-500"}`}
            onClick={() => setActiveTab("test_fee")}
          >
            Test Fees
          </button>
          <button
            className={`px-4 py-2 font-medium ${activeTab === "payout" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-gray-500"}`}
            onClick={() => setActiveTab("payout")}
          >
            Payouts
          </button>
          <button
            className={`px-4 py-2 font-medium ${activeTab === "commission" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-gray-500"}`}
            onClick={() => setActiveTab("commission")}
          >
            Commissions
          </button>
        </div>

        {/* Transactions Table */}
        <div className="bg-white rounded-xl shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-4 text-center">
                      Loading transactions...
                    </td>
                  </tr>
                ) : filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-4 text-center text-gray-500">
                      No transactions found
                    </td>
                  </tr>
                ) : (
                  filteredTransactions.map((txn) => (
                    <motion.tr 
                      key={txn.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      whileHover={{ backgroundColor: "#f9fafb" }}
                      className="transition-colors"
                    >
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{getTypeLabel(txn.type)}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{txn.user}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className={`text-sm font-semibold ${
                          txn.type === "commission" || txn.type === "test_fee" 
                            ? "text-green-600" 
                            : "text-red-600"
                        }`}>
                          {txn.type === "payout" ? "-" : "+"}₹{txn.amount}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getStatusBadge(txn.status)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {txn.date}
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

export default TransactionsScreen;