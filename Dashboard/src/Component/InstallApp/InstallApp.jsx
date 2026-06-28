import React from 'react';
import { Box, Grid, Typography, Button, Stack } from '@mui/material';
import AppleIcon from '@mui/icons-material/Apple';
import AndroidIcon from '@mui/icons-material/Android';
import QrCode2Icon from '@mui/icons-material/QrCode2';
import AppMockup from '../../assets/iphone 12 Pro Max.png';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { useTranslation } from 'react-i18next';

const MotionBox = motion(Box);

const InstallAppSection = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.6 });

  return (
    <Box
    
      id="install"
      ref={ref}
      sx={{
        backgroundColor: '#fff7f2',
        px: { xs: 3, md: 10 },
        py: { xs: 6, md: 10 },
        overflow: 'hidden',
      }}
    >
      <Grid container spacing={6} alignItems="center">
        {/* Text links */}
        <Grid item xs={12} md={6} sx={{width:'40%'}}>
          <MotionBox
            initial={{ opacity: 0, x: -100 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8 }}
          >
            <Typography
              variant="h4"
              sx={{ fontWeight: 'bold', color: '#d35400', mb: 2,  }}
            >
              {t('Intel')}
            </Typography>
            <Typography sx={{ color: '#555', mb: 3 ,}}>
              {t('Miete')}
            </Typography>

            <Stack direction="row" spacing={2} alignItems="center" mb={3} >
              <QrCode2Icon sx={{ fontSize: 60, color: '#d35400' }} />
              <Typography variant="body2" sx={{ maxWidth: 200 ,}}>
              {t('Scannen')}
              </Typography>
            </Stack>

            <Stack direction="row" spacing={2} >
              <Button
                variant="contained"
                sx={{
                  backgroundColor: '#000',
                  textTransform: 'none',
                  px: 3,
                  py: 1,
                  borderRadius: 2,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    backgroundColor: '#333',
                    boxShadow: '0px 6px 20px rgba(0,0,0,0.3)',
                    transform: 'scale(1.05)',

                  },
                }}
                startIcon={<AppleIcon />}
              >
                {t('App')}
              </Button>
              <Button
                variant="contained"
                sx={{
                  backgroundColor: '#34a853',
                  textTransform: 'none',
                  px: 3,
                  py: 1,
                  borderRadius: 2,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    backgroundColor: '#2c8c46',
                    boxShadow: '0px 6px 20px rgba(0,0,0,0.3)',
                    transform: 'scale(1.05)',
                  },
                }}
                startIcon={<AndroidIcon />}
              >
                {t('Google')}
              </Button>
            </Stack>
          </MotionBox>
        </Grid >

        {/* Bild rechts */}
        <Grid item xs={12} md={6}>
          <MotionBox
            component="img"
            src={AppMockup}
            alt="App Preview"
            initial={{ opacity: 0, x: 100 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8 }}
            sx={{
              width: '100%',
              maxWidth: 300,
              display: 'block',
              mx: 'auto',
              animation: 'float 3s ease-in-out infinite',
              
            }}
          />
        </Grid>
      </Grid>

      {/* Float Animation */}
      <style>{`
        @keyframes float {
          0% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
          100% { transform: translateY(0); }
        }
      `}</style>
    </Box>
  );
};

export default InstallAppSection;
