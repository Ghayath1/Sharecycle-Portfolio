import React, { useState } from 'react';
import {
  Box,
  Button,
  TextField,
  Typography,
  Paper,
} from '@mui/material';
import SendIcon from '@mui/icons-material/Send';
import EmailIcon from '@mui/icons-material/Email';
import PersonIcon from '@mui/icons-material/Person';
import Logo from '../../assets/Logo.png';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { useTranslation } from 'react-i18next';

const MotionBox = motion(Box);

const ContactUsOrange = () => {
  const { t } = useTranslation();
  const [form, setForm] = useState({ name: '', email: '', message: '' });
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.5});

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log('Message sent:', form);
  };

  return (
    <Box
    id="contact"
      ref={ref}
      sx={{
        backgroundColor: '#fdf2ec',
        minHeight: '100vh',
        py: 6,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Paper
        elevation={3}
        sx={{
          width: '90%',
          maxWidth: 1000,
          borderRadius: 3,
          overflow: 'hidden',
          display: 'flex',
          flexDirection: { xs: 'column', md: 'row' },
        }}
      >
        {/* Left: Form animated from left */}
        <MotionBox
          initial={{ opacity: 0, x: -100 }}
          animate={inView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.8 }}
          sx={{ flex: 1, backgroundColor: 'white', p: 4 }}
        >
          <Typography variant="h4" fontWeight="bold" mb={3} color="#d35400">
            {t('Contact')}
          </Typography>

          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              placeholder="Name"
              name="name"
              value={form.name}
              onChange={handleChange}
              InputProps={{
                startAdornment: <PersonIcon sx={{ mr: 1, color: '#d35400' }} />,
                sx: {
                  borderRadius: 10,
                  backgroundColor: '#f8f4f3',
                  px: 2,
                },
              }}
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              placeholder="Email"
              name="email"
              value={form.email}
              onChange={handleChange}
              InputProps={{
                startAdornment: <EmailIcon sx={{ mr: 1, color: '#d35400' }} />,
                sx: {
                  borderRadius: 10,
                  backgroundColor: '#f8f4f3',
                  px: 2,
                },
              }}
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              multiline
              rows={4}
              placeholder="Message"
              name="message"
              value={form.message}
              onChange={handleChange}
              InputProps={{
                sx: {
                  borderRadius: 4,
                  backgroundColor: '#f8f4f3',
                  px: 2,
                },
              }}
              sx={{ mb: 3 }}
            />

            <Button
              type="submit"
              variant="contained"
              fullWidth
              sx={{
                borderRadius: 10,
                textTransform: 'none',
                fontWeight: 'bold',
                backgroundColor: '#d35400',
                color: 'white',
                py: 1.5,
                fontSize: '1rem',
                '&:hover': {
                  backgroundColor: '#b84300',
                },
              }}
              endIcon={<SendIcon />}
            >
              {t('Message')}
            </Button>
          </form>
        </MotionBox>

        {/* Right: Image animated from right */}
        <MotionBox
          initial={{ opacity: 0, x: 100 }}
          animate={inView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
          sx={{
            flex: 1,
            backgroundColor: '#E06037',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            p: 2,
          }}
        >
          <img
            src={Logo}
            alt="Contact illustration"
            style={{ maxWidth: '100%', height: 'auto' }}
          />
        </MotionBox>
      </Paper>
    </Box>
  );
};

export default ContactUsOrange;
