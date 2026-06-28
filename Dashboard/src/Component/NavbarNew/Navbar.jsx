import React, { useState } from 'react';
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  Box,
  Drawer,
  List,
  ListItem,
  ListItemText,
  useMediaQuery,
  Button,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import { useTheme } from '@mui/material/styles';
import { useNavigate } from 'react-router-dom';
import Logo from '../../assets/Logo.png';
import LanguageToggle from '../../Component/Language/Language'; // Pfad ggf. anpassen

const navItems = [
  { label: 'Home', target: 'hero' },
  { label: 'Mission', target: 'mission' },
  { label: 'About', target: 'about' },
  { label: 'App', target: 'install' },
  { label: 'Join Us', target: 'join' },
  { label: 'Contact', target: 'contact' },
];

const scrollToSection = (id) => {
  const el = document.getElementById(id);
  if (el) {
    window.scrollTo({
      top: el.offsetTop - 64,
      behavior: 'smooth',
    });
  }
};

const Navbar = () => {
  const [open, setOpen] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const navigate = useNavigate();

  return (
    <>
      <AppBar position="fixed" sx={{ backgroundColor: '#E06037', boxShadow: 1 }}>
        <Toolbar sx={{ justifyContent: 'center', position: 'relative' }}>
          {/* Logo */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              cursor: 'pointer',
              position: 'absolute',
              left: 16,
            }}
            onClick={() => scrollToSection('hero')}
          >
            <img src={Logo} alt="Logo" style={{ height: 40, marginRight: 10 }} />
            <Typography variant="h6" sx={{ color: '#fff', fontWeight: 'bold' }}>
              ShareCycle
            </Typography>
          </Box>

          {/* Desktop Navigation */}
          {!isMobile && (
            <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2 }}>
              {navItems.map(({ label, target }) => (
                <Button
                  key={target}
                  onClick={() => scrollToSection(target)}
                  sx={{
                    color: '#fff',
                    textTransform: 'none',
                    fontWeight: 500,
                    '&:hover': { color: '#ffe3d1' },
                  }}
                >
                  {label}
                </Button>
              ))}
            </Box>
          )}

          {/* Right: Language + Login */}
          {!isMobile && (
            <Box sx={{ position: 'absolute', right: 16, display: 'flex', alignItems: 'center' }}>
              <LanguageToggle />
              <Button
                onClick={() => navigate('/login')}
                sx={{
                  backgroundColor: '#fff',
                  color: '#E06037',
                  textTransform: 'none',
                  fontWeight: 'bold',
                  px: 3,
                  borderRadius: 3,
                  ml: 1,
                  '&:hover': {
                    backgroundColor: '#ffe3d1',
                  },
                }}
              >
                Login
              </Button>
            </Box>
          )}

          {/* Mobile Burger Icon */}
          {isMobile && (
            <IconButton onClick={() => setOpen(true)} edge="end" sx={{ position: 'absolute', right: 16 }}>
              <MenuIcon sx={{ color: '#fff' }} />
            </IconButton>
          )}
        </Toolbar>
      </AppBar>

      {/* Mobile Drawer */}
      <Drawer anchor="right" open={open} onClose={() => setOpen(false)}>
        <Box sx={{ width: 250, mt: 8 }}>
          <List>
            {navItems.map(({ label, target }) => (
              <ListItem
                button
                key={target}
                onClick={() => {
                  scrollToSection(target);
                  setOpen(false);
                }}
              >
                <ListItemText
                  primary={label}
                  primaryTypographyProps={{
                    sx: {
                      color: '#E06037',
                      fontWeight: 'bold',
                      pl: 1,
                      '&:hover': { color: '#ff8050' },
                    },
                  }}
                />
              </ListItem>
            ))}
            <ListItem
              button
              onClick={() => {
                navigate('/login');
                setOpen(false);
              }}
            >
              <ListItemText
                primary="Login"
                primaryTypographyProps={{
                  sx: {
                    color: '#E06037',
                    fontWeight: 'bold',
                    pl: 1,
                    '&:hover': { color: '#ff8050' },
                  },
                }}
              />
            </ListItem>
          </List>
        </Box>
      </Drawer>

      <Toolbar />
    </>
  );
};

export default Navbar;
