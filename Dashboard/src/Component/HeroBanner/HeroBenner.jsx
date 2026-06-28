import React, { useEffect, useRef, useState } from 'react';
import { Box, Typography, Button, Grid } from '@mui/material';
import HeroImage from '../../assets/Bike1.png'; // Dein Bild
import { useTranslation } from 'react-i18next';

const HeroBanner = () => {
  const imageRef = useRef(null);
  const [scrollX, setScrollX] = useState(0);
  const { t } = useTranslation();
  useEffect(() => {
    const handleScroll = () => {
      const offset = window.scrollY;
      setScrollX(offset * 0.2); // Geschwindigkeit des Scroll-Effekts anpassen
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <Box
      sx={{
        background: 'linear-gradient(to right, #fff5f0, #ffe8db)',
        py: { xs: 8, md: 12 },
        px: { xs: 2, md: 10 },
        overflow: 'hidden',
      }}
    >
      <Grid container spacing={4} alignItems="center">
        {/* Text Left */}
        <Grid item xs={12} md={6}>
          <Typography
            variant="h2"
            sx={{
              fontWeight: 'bold',
              fontSize: { xs: '2rem', md: '3rem' },
              color: '#d35400',
              mb: 2,
              animation: 'fadeInUp 1s ease-out',
            }}
          >
            {t('Hero text')}
            
          </Typography>

          <Typography
            variant="body1"
            sx={{
              fontSize: '1.1rem',
              color: '#555',
              mb: 4,
              maxWidth: 500,
              animation: 'fadeInUp 1.4s ease-out',
            }}
          >
            {t('Hero Body')}
          </Typography>

          <Box sx={{ display: 'flex', justifyContent: { xs: 'center', md: 'flex-start' } }}>
            <Button
              variant="contained"
              size="large"
              sx={{
                backgroundColor: '#d35400',
                textTransform: 'none',
                fontSize: '1rem',
                px: 4,
                py: 1.5,
                borderRadius: 3,
                width: 'fit-content',
                boxShadow: 'none',
                transition: 'all 0.3s ease',
                '&:hover': {
                  backgroundColor: '#e36b17',
                  boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.2)',
                },
              }}
            >
              {t('Login')}
            </Button>
          </Box>
        </Grid>

        {/* Image Right */}
        <Grid item xs={12} md={6}>
          <Box
            ref={imageRef}
            component="img"
            src={HeroImage}
            alt="Hero Bike"
            sx={{
              width: '100%',
              maxWidth: 500,
              display: 'block',
              mx: 'auto',
              transform: `translateX(${scrollX}px)`,
              transition: 'transform 0.1s ease-out',
            }}
          />
        </Grid>
      </Grid>

      {/* Keyframes for fade-in animation */}
      <style>
        {`
          @keyframes fadeInUp {
            from {
              opacity: 0;
              transform: translateY(30px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }
        `}
      </style>
    </Box>
  );
};

export default HeroBanner;
