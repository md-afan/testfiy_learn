import React, { useState, useEffect } from "react";
import { motion } from "framer-motion";
import {
  FiDownload,
  FiBarChart2,
  FiTrendingUp,
  FiUser,
  FiBook,
} from "react-icons/fi";

const DashboardScreen = () => {
  const [stats, setStats] = useState({
    teachers: 42,
    students: 1286,
    tests: 87,
    revenue: 125640,
    activeTests: 24,
    avgResponse: "8.2h",
    systemHealth: "98.7%",
  });

  const [loading, setLoading] = useState(true);
  const [timeFilter, setTimeFilter] = useState("monthly");

  useEffect(() => {
    // Simulate data loading
    const timer = setTimeout(() => {
      setLoading(false);
    }, 800);

    return () => clearTimeout(timer);
  }, []);

  // Revenue data for different time periods
  const revenueData = {
    weekly: [12000, 18000, 15000, 22000, 19000, 25000, 21000],
    monthly: [
      12000, 19000, 15000, 22000, 18000, 25000, 21000, 23000, 27000, 24000,
      26000, 29000,
    ],
    yearly: [
      95000, 110000, 125000, 140000, 160000, 185000, 205000, 225000, 245000,
      265000, 285000, 310000,
    ],
  };

  // Test growth data
  const testGrowthData = {
    weekly: [5, 8, 10, 12, 15, 18, 20],
    monthly: [5, 12, 8, 15, 18, 24, 20, 28, 25, 30, 35, 40],
    yearly: [50, 70, 90, 110, 130, 160, 190, 220, 250, 290, 330, 380],
  };

  // Recent activity data
  const recentActivity = [
    {
      user: "John Doe",
      action: "created a new test",
      time: "2 mins ago",
      icon: <FiBook className="text-blue-500" />,
    },
    {
      user: "Sarah Smith",
      action: "completed payment",
      time: "15 mins ago",
      icon: <FiBarChart2 className="text-green-500" />,
    },
    {
      user: "Michael Chen",
      action: "joined as teacher",
      time: "1 hour ago",
      icon: <FiUser className="text-purple-500" />,
    },
    {
      user: "Emma Wilson",
      action: "withdrew earnings",
      time: "3 hours ago",
      icon: <FiTrendingUp className="text-yellow-500" />,
    },
  ];

  // Custom bar chart component
  const BarChart = ({ data, color, label }) => {
    const maxValue = Math.max(...data);
    const height = 160;

    return (
      <div className="flex items-end h-full gap-1.5 px-2 w-full">
        {data.map((value, index) => (
          <div key={index} className="flex flex-col items-center flex-1">
            <motion.div
              initial={{ height: 0 }}
              animate={{ height: `${(value / maxValue) * 100}%` }}
              transition={{ duration: 1, delay: index * 0.1 }}
              className={`w-full rounded-t ${color}`}
              style={{ maxHeight: `${height}px` }}
            />
            <span className="text-[10px] text-gray-500 mt-1">
              {label === "months"
                ? ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"][
                    index
                  ]
                : ["M", "T", "W", "T", "F", "S", "S"][index]}
            </span>
          </div>
        ))}
      </div>
    );
  };

  // Custom line chart component
  const LineChart = ({ data, color }) => {
    const maxValue = Math.max(...data);
    const height = 160;

    return (
      <div className="relative h-full">
        <div className="absolute bottom-0 left-0 right-0 flex items-end gap-1.5">
          {data.map((value, index) => (
            <motion.div
              key={index}
              initial={{ height: 0 }}
              animate={{ height: `${(value / maxValue) * 100}%` }}
              transition={{ duration: 1, delay: index * 0.1 }}
              className={`w-full rounded-t ${color}`}
              style={{ maxHeight: `${height}px` }}
            />
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen  p-4 md:p-6 ">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between mb-6 gap-4">
          <div>
            <motion.h1
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-2xl md:text-3xl font-bold text-gray-800 dark:text-white"
            >
              Dashboard Overview
            </motion.h1>
            <p className="text-gray-600 mt-1 dark:text-gray-300">
              Track your platform's performance metrics
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="relative">
              <button className="p-2 rounded-lg bg-white shadow text-gray-500 hover:bg-gray-50 transition">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z" />
                </svg>
              </button>
              <div className="absolute top-0 right-0 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></div>
            </div>

            <div className="bg-white shadow rounded-lg px-3 py-2">
              <select
                value={timeFilter}
                onChange={(e) => setTimeFilter(e.target.value)}
                className="bg-transparent text-sm font-medium focus:outline-none"
              >
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </select>
            </div>

            <button className="bg-white shadow rounded-lg px-3 py-2 flex items-center text-sm font-medium text-gray-700 hover:bg-gray-50 transition">
              <FiDownload className="mr-2" /> Export
            </button>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-6">
          <StatCard
            title="Teachers"
            value={stats.teachers}
            change="+12.4%"
            icon={<FiUser className="text-xl" />}
            color="from-blue-500 to-cyan-500"
            loading={loading}
          />
          <StatCard
            title="Students"
            value={stats.students}
            change="+8.2%"
            icon="👨‍🎓"
            color="from-purple-500 to-pink-500"
            loading={loading}
          />
          <StatCard
            title="Tests"
            value={stats.tests}
            change="+5.3%"
            icon={<FiBook className="text-xl" />}
            color="from-amber-500 to-orange-500"
            loading={loading}
          />
          <StatCard
            title="Revenue"
            value={`₹${stats.revenue.toLocaleString()}`}
            change="+24.5%"
            icon={<FiBarChart2 className="text-xl" />}
            color="from-green-500 to-teal-500"
            loading={loading}
          />
        </div>

        {/* Charts Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          {/* Revenue Chart Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl shadow overflow-hidden"
          >
            <div className="p-5 border-b">
              <div className="flex justify-between items-center">
                <h2 className="text-lg font-semibold text-gray-800">
                  Revenue Overview
                </h2>
                <span className="text-sm bg-green-100 text-green-800 px-2 py-1 rounded-full">
                  +24.5%
                </span>
              </div>
              <p className="text-gray-600 text-sm mt-1">
                Total: ₹{stats.revenue.toLocaleString()}
              </p>
            </div>
            <div className="p-5">
              <div className="h-64">
                <BarChart
                  data={revenueData[timeFilter]}
                  color="bg-gradient-to-t from-blue-500 to-cyan-500"
                  label={timeFilter === "yearly" ? "months" : "days"}
                />
              </div>
            </div>
          </motion.div>

          {/* Test Growth Chart Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-xl shadow overflow-hidden"
          >
            <div className="p-5 border-b">
              <div className="flex justify-between items-center">
                <h2 className="text-lg font-semibold text-gray-800">
                  Test Growth
                </h2>
                <span className="text-sm bg-green-100 text-green-800 px-2 py-1 rounded-full">
                  +18.2%
                </span>
              </div>
              <p className="text-gray-600 text-sm mt-1">
                Total: {stats.tests} tests
              </p>
            </div>
            <div className="p-5">
              <div className="h-64">
                <LineChart
                  data={testGrowthData[timeFilter]}
                  color="bg-gradient-to-t from-purple-500 to-pink-500"
                />
              </div>
            </div>
          </motion.div>
        </div>

        {/* Bottom Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Quick Stats */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white rounded-xl shadow overflow-hidden lg:col-span-2"
          >
            <div className="p-5 border-b">
              <h2 className="text-lg font-semibold text-gray-800">
                Platform Metrics
              </h2>
            </div>
            <div className="p-5">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                <MetricCard
                  title="Pending Tests"
                  value={stats.activeTests}
                  icon={<FiBook className="text-indigo-500" />}
                  color="bg-indigo-100"
                />
                <MetricCard
                  title="Avg. Response Time"
                  value={stats.avgResponse}
                  icon={<FiTrendingUp className="text-amber-500" />}
                  color="bg-amber-100"
                />
                <MetricCard
                  title="System Health"
                  value={stats.systemHealth}
                  icon={<FiBarChart2 className="text-green-500" />}
                  color="bg-green-100"
                />
              </div>
            </div>
          </motion.div>

          {/* Recent Activity */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-white rounded-xl shadow overflow-hidden"
          >
            <div className="p-5 border-b flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-800">
                Recent Activity
              </h2>
              <button className="text-indigo-600 hover:text-indigo-800 text-sm font-medium">
                View All
              </button>
            </div>
            <div className="p-3">
              <div className="space-y-3">
                {recentActivity.map((activity, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 * index }}
                    className="flex items-start p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                  >
                    <div className="p-2 bg-white rounded-lg shadow mr-3">
                      {activity.icon}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-800">
                        {activity.user}
                      </p>
                      <p className="text-gray-600 text-sm">{activity.action}</p>
                    </div>
                    <div className="text-xs text-gray-500 whitespace-nowrap">
                      {activity.time}
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

// Stat Card Component
const StatCard = ({ title, value, change, icon, color, loading }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className={`bg-gradient-to-br ${color} rounded-xl p-0.5 shadow-lg `}
  >
    <div className="bg-white dark:bg-black h-full rounded-xl p-5 flex flex-col">
      <div className="flex justify-between items-start">
        <div>
          <div className="text-gray-500 text-sm font-medium">{title}</div>
          {loading ? (
            <div className="h-8 w-24 bg-gray-200 rounded animate-pulse mt-2"></div>
          ) : (
            <div className="text-2xl font-bold text-gray-800 mt-1">{value}</div>
          )}
        </div>
        <div className="bg-gray-100 p-2 rounded-lg">
          {typeof icon === "string" ? (
            <span className="text-xl">{icon}</span>
          ) : (
            React.cloneElement(icon, { className: "text-xl" })
          )}
        </div>
      </div>

      <div className="mt-4 flex items-center">
        <div className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs font-medium">
          {change}
        </div>
        <div className="text-gray-500 text-xs ml-2">vs previous period</div>
      </div>

      {/* Progress bar */}
      <div className="mt-3">
        <div className="h-1.5 w-full bg-gray-200 rounded-full overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: "85%" }}
            transition={{ duration: 1 }}
            className="h-full bg-gradient-to-r from-gray-800 to-gray-600"
          />
        </div>
      </div>
    </div>
  </motion.div>
);

// Metric Card Component
const MetricCard = ({ title, value, icon, color }) => (
  <div className={`${color} p-4 rounded-lg`}>
    <div className="flex items-center justify-between">
      <div>
        <div className="text-gray-500 text-sm font-medium">{title}</div>
        <div className="text-xl font-bold text-gray-800 mt-1">{value}</div>
      </div>
      <div className="bg-white p-2 rounded-lg shadow">{icon}</div>
    </div>
  </div>
);

export default DashboardScreen;
