// src/layouts/MainLayout.jsx
import React from 'react';
import Navbar from '../Component/Navbar/Navbar';
import { Outlet } from 'react-router-dom';

const MainLayout = () => {
  return (
    <>
      <Navbar />
      <main>
        <Outlet /> {/* zeigt die aktuelle Seite */}
      </main>
    </>
  );
};

export default MainLayout;
