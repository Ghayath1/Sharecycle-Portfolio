import React from 'react';
import {
  Box,
  Container,
  Grid,
  Typography,
  Link,
  IconButton
} from '@mui/material';
import FacebookIcon from '@mui/icons-material/Facebook';
import InstagramIcon from '@mui/icons-material/Instagram';
import TwitterIcon from '@mui/icons-material/Twitter';
import Logo from '../../assets/Logo.png';
import { useTranslation } from 'react-i18next';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';

const MotionBox = motion(Box);
const MotionTypography = motion(Typography);

const Footer = () => {
   const { t } = useTranslation();
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.4 });

  return (
    <Box
      ref={ref}
      sx={{
        backgroundColor: '#d35400',
        color: 'white',
        mt: 6,
        py: 4,
        overflow: 'hidden',
      }}
    >
      <Container maxWidth="lg">
        <Grid container spacing={4} justifyContent="space-between" alignItems="center">
          
          {/* Logo + Beschreibung */}
          <Grid item xs={12} sm={4}>
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6 }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <img src={Logo} alt="Logo" style={{ width: 140, marginRight: 100 }} />
              </Box>
              <Typography variant="body2">
                {t('smart')}
              </Typography>
            </motion.div>
          </Grid>

          {/* Quick Links */}
          <Grid item xs={12} sm={4}>
            <MotionTypography
              variant="h6"
              fontWeight="bold"
              gutterBottom
              initial={{ opacity: 0, y: 40 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              {t('Quick')}
            </MotionTypography>
            <MotionBox
              initial={{ opacity: 0, y: 40 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: 0.3 }}
            >
              {[
                { label: 'Home', href: '/' },
                { label: 'Contact', href: '/contact' },
                { label: 'About', href: '/about' },
              ].map(({ label, href }) => (
                <Link
                  key={label}
                  href={href}
                  underline="none"
                  color="inherit"
                  display="block"
                  sx={{
                    mb: 0.5,
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      color: '#ffffff',
                      pl: 1,
                      textDecoration: 'underline',
                    },
                  }}
                >
                  {label}
                </Link>
              ))}
            </MotionBox>
          </Grid>

          {/* Social Media */}
          <Grid item xs={12} sm={4}>
            <MotionTypography
              variant="h6"
              fontWeight="bold"
              gutterBottom
              initial={{ opacity: 0, y: 40 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: 0.4 }}
            >
              {t('Follow')}
            </MotionTypography>
            <MotionBox
              initial={{ opacity: 0, y: -20 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: 0.5 }}
            >
              <IconButton href="https://facebook.com" target="_blank" sx={{ color: 'white' }}>
                <FacebookIcon />
              </IconButton>
              <IconButton href="https://instagram.com" target="_blank" sx={{ color: 'white' }}>
                <InstagramIcon />
              </IconButton>
              <IconButton href="https://twitter.com" target="_blank" sx={{ color: 'white' }}>
                <TwitterIcon />
              </IconButton>
            </MotionBox>
          </Grid>
        </Grid>

        {/* Copyright */}
        <MotionBox
          mt={4}
          textAlign="center"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <Typography variant="body2" color="white">
            &copy; 2025 Ghayath. All rights reserved.
          </Typography>
        </MotionBox>
      </Container>
    </Box>
  );
};

export default Footer;
