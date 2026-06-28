// src/Routes.jsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

import MainLayout from '../layouts/MainLayout';
import HomePage from '../pages/HomePage/Index';
import AdsPage from '../pages/AdsPage/Index';
import ChatPage from '../pages/ChatPage/Index';
import EditAdPage from '../pages/EditAdPage/Index';
import OpenChatPage from '../pages/OpenChatPage/Index';
import OrderPage from '../pages/OrderPage/Index';
import ProfilePage from '../pages/ProfilePage/Index';
import UserPage from '../pages/UserPage/Index';
import ViewOrderPage from '../pages/ViewOrderPage/Index';
import Landing from '../pages/LandingPage/Index'

import LoginPage from '../pages/LoginPage/LoginPage'; // nur Login ohne Navbar

const AppRoutes = () => {
  return (
    <Router>
      <Routes>
        {/* Seiten mit Navbar */}
        <Route element={<MainLayout />}>
          <Route path="/summary" element={<HomePage />} />
          { <Route path="/ads" element={<AdsPage />} /> } 
          <Route path="/chat" element={<ChatPage />} />
          <Route path="/edit-ad/:id" element={<EditAdPage />} />
          <Route path="/open-chat" element={<OpenChatPage />} />
          <Route path="/orders" element={<OrderPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/users" element={<UserPage />} />
          <Route path="/view-order" element={<ViewOrderPage />} />
          <Route path="/" element={<Landing />} />
        </Route>

        {/* Login ohne Layout/Navbar */}
        <Route path="/login" element={<LoginPage />} />
      </Routes>
    </Router>
  );
};

export default AppRoutes;
