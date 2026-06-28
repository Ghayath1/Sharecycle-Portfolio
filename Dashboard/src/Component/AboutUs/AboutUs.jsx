import React from 'react';
import { Box, Typography, Paper } from '@mui/material';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import Bike3 from '../../assets/Bike3.avif';
import { useTranslation } from 'react-i18next';

const MotionPaper = motion(Paper);
 

const AboutUs = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.6});

  return (
    <Box
    id="about"
      ref={ref}
      sx={{
        position: 'relative',
        backgroundImage: `url(${Bike3})`,
        backgroundAttachment: 'fixed',
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        py: { xs: 8, md: 12 },
        px: { xs: 2, md: 10 },
        color: 'white',
        overflow: 'hidden',
      }}
    >
      <MotionPaper
        elevation={6}
        initial={{ opacity: 0, y: 60 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8 }}
        sx={{
          maxWidth: 900,
          mx: 'auto',
          p: { xs: 4, md: 6 },
          backgroundColor: 'rgba(211, 84, 0, 0.93)', // #d35400 mit Transparenz
          borderRadius: 4,
          textAlign: 'left',
        }}
      >
        <Typography variant="h4" fontWeight="bold" sx={{ color: '#fff', mb: 2 }}>
          {t('Über')}
        </Typography>

        <Typography sx={{ mb: 2, fontSize: '1.1rem', color: '#fff' }}>
         {t('Texte')}
        </Typography>

        <Typography sx={{ fontSize: '1.1rem', color: '#fff' }}>
         {t('Plat')}
        </Typography>
      </MotionPaper>
    </Box>
  );
};

export default AboutUs;
