import React, { useState, useEffect } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "./services/firebase";
import { ThemeProvider } from "./context/ThemeContext";
import SidebarLayout from "./components/SidebarLayout";
import LoginPage from "./screens/LoginPage";
import DashboardScreen from "./screens/DashboardScreen";
import TeacherRequestsScreen from "./screens/TeacherRequestsScreen";
import AllTestsScreen from "./screens/AllTestsScreen";
import TransactionsScreen from "./screens/TransactionsScreen";
import WithdrawalsScreen from "./screens/WithdrawalsScreen";
import NotificationsScreen from "./screens/NotificationsScreen";
import AccessDenied from "./screens/AccessDenied";
import AdminProfileScreen from "./screens/AdminProfileScreen";

const App = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">
            Checking authentication...
          </p>
        </div>
      </div>
    );
  }

  return (
    <ThemeProvider>
      <Router>
        <Routes>
          {/* <Route 
            path="/login" 
            element={user ? <Navigate to="/" replace /> : <LoginPage />} 
          /> */}

          {/* {user ? ( */}

          <Route element={<SidebarLayout user={user} />}>
            <Route index element={<DashboardScreen />} />
            <Route
              path="/teacher-requests"
              element={<TeacherRequestsScreen />}
            />
            <Route path="/tests" element={<AllTestsScreen />} />
            <Route path="/transactions" element={<TransactionsScreen />} />
            <Route path="/withdrawals" element={<WithdrawalsScreen />} />
            <Route path="/notifications" element={<NotificationsScreen />} />
            <Route path="/profile" element={<AdminProfileScreen />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
          {/* ) : (
            <>
              <Route path="/access-denied" element={<AccessDenied />} />
              <Route path="*" element={<Navigate to="/login" replace />} />
            </>
          )} */}
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
