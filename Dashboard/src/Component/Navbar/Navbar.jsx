import React, { useState } from 'react';
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Box,
  Tooltip
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import PersonIcon from '@mui/icons-material/Person';
import EuroIcon from '@mui/icons-material/Euro';
import ShoppingBagIcon from '@mui/icons-material/ShoppingBag';
import TwoWheelerIcon from '@mui/icons-material/TwoWheeler';
import MessageIcon from '@mui/icons-material/Message';
import EditIcon from '@mui/icons-material/Edit';
import ViewListIcon from '@mui/icons-material/ViewList';
import LogoutIcon from '@mui/icons-material/Logout';
import HomeIcon from '@mui/icons-material/Home';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Logo from '../../assets/Logo.png';
import Langauge from '../../Component/Language/Language'

const menuItems = [
  { label: 'Summary', icon: <HomeIcon />, path: '/summary' },
  { label: 'Users', icon: <PersonIcon />, path: '/users' },
  { label: 'Orders', icon: <ShoppingBagIcon />, path: '/orders' },
  { label: 'Bycicles', icon: <TwoWheelerIcon />, path: '/ads' },
  { label: 'Chats', icon: <MessageIcon />, path: '/chat' },
  { label: 'Profile', icon: <PersonIcon />, path: '/profile' },
  { label: 'ViewOrder', icon: <ViewListIcon />, path: '/view-order' },
  { label: 'Logout', icon: <LogoutIcon />, path: '/login' },
];

const Navbar = () => {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const navigate = useNavigate();
  const { i18n } = useTranslation();

  const toggleDrawer = (open) => () => {
    setDrawerOpen(open);
  };

  const handleNavigation = (path) => {
    navigate(path);
    setDrawerOpen(false);
  };

  // 🌐 Language toggle logic
  const toggleLanguage = () => {
    const newLang = i18n.language === 'de' ? 'en' : 'de';
    i18n.changeLanguage(newLang);
  };

  const flagSrc = i18n.language === 'de'
    ? 'https://flagcdn.com/w40/de.png'
    : 'https://flagcdn.com/w40/gb.png';

  const flagAlt = i18n.language === 'de' ? 'Deutsch' : 'English';

  return (
    <>
      <AppBar
        position="static"
        sx={{
          backgroundColor: 'white',
          color: '#e9744c',
          boxShadow: '0px 1px 4px rgba(0,0,0,0.1)',
        }}
      >
        <Toolbar sx={{ justifyContent: 'space-between' }}>
          <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
            ShareCycle
          </Typography>

          {/* Rechts: Flaggen-Button + Menü-Icon */}
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Tooltip title={`Sprache: ${flagAlt}`}>
              <IconButton onClick={toggleLanguage} sx={{ mr: 1 }}>
                <img
                  src={flagSrc}
                  alt={flagAlt}
                  width="30"
                  height="20"
                  style={{ borderRadius: '3px' }}
                />
              </IconButton>
            </Tooltip>
            <IconButton edge="end" onClick={toggleDrawer(true)}>
              <MenuIcon sx={{ color: '#e9744c' }} />
            </IconButton>
          </Box>
        </Toolbar>
      </AppBar>

      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={toggleDrawer(false)}
        PaperProps={{
          sx: {
            backgroundColor: '#d35400',
            width: 260,
            color: 'white',
          },
        }}
      >
        <Box sx={{ p: 3, textAlign: 'center' }}>
          <img
            src={Logo}
            alt="Share Cycle"
            style={{ width: 100, marginBottom: 10, cursor: 'pointer' }}
            onClick={() => handleNavigation('/')}
          />
          <Typography variant="h6" fontWeight="bold">
            Share <span style={{ color: 'white' }}>Cycle</span>
          </Typography>

          <List sx={{ mt: 4 }}>
            {menuItems.map(({ label, icon, path }) => (
              <ListItem
                button
                key={label}
                onClick={() => handleNavigation(path)}
                sx={{
                  '&:hover': {
                    cursor: 'pointer',
                    backgroundColor: '#e9744c',
                  },
                }}
              >
                <ListItemIcon sx={{ color: 'white' }}>{icon}</ListItemIcon>
                <ListItemText primary={label} />
              </ListItem>
            ))}
          </List>
        </Box>
      </Drawer>
    </>
  );
};

export default Navbar;
