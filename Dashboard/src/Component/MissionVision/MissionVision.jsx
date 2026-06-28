import React from 'react';
import { Box, Grid, Typography, Paper } from '@mui/material';
import EmojiObjectsIcon from '@mui/icons-material/EmojiObjects';
import VisibilityIcon from '@mui/icons-material/Visibility';
import { useInView } from 'react-intersection-observer';
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';


const MotionPaper = motion(Paper);

const MissionVision = () => {
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.2 });
  const { t } = useTranslation();

  return (
    <Box
    id="mission"
      sx={{
        background: 'linear-gradient(to bottom, #fff5f0, #ffe8db)',
        py: { xs: 6, md: 10 },
        px: { xs: 3, md: 12 },
      }}
    >
      <Typography
        variant="h3"
        fontWeight="bold"
        align="center"
        sx={{ color: '#d35400', mb: { xs: 5, md: 8 } }}
      >
        {t('Mission')}
      </Typography>

      <Grid
        container
        spacing={4}
        justifyContent="center"
        ref={ref}
        sx={{ display: 'flex', flexDirection: 'row' }}
      >
        {/* Mission */}
        <Grid item xs={12} sm={6}>
          <MotionPaper
            elevation={5}
            initial={{ opacity: 0, y: 50 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
            sx={{
              p: { xs: 4, md: 5 },
              borderRadius: 4,
              width: '320px',
              backgroundColor: '#ffffff',
              textAlign: 'center',
              transition: 'transform 0.3s ease',
              '&:hover': {
                transform: 'scale(1.02)',
              },
            }}
          >
            <EmojiObjectsIcon sx={{ fontSize: 60, color: '#d35400', mb: 2 }} />
            <Typography variant="h5" fontWeight="bold" sx={{ color: '#d35400', mb: 2 }}>
              {t('Unsere')}
            </Typography>
            <Typography sx={{ fontSize: '1.05rem', color: '#555' }}>
             {t('Our')}
            </Typography>
          </MotionPaper>
        </Grid>

        {/* Vision */}
        <Grid item xs={12} sm={6}>
          <MotionPaper
            elevation={5}
            initial={{ opacity: 0, y: 50 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.5 }}
            sx={{
              p: { xs: 4, md: 5 },
              borderRadius: 4,
              width: '320px',
              height:'230px',
              backgroundColor: '#ffffff',
              textAlign: 'center',
              transition: 'transform 0.3s ease',
              '&:hover': {
                transform: 'scale(1.02)',
              },
            }}
          >
            <VisibilityIcon sx={{ fontSize: 60, color: '#d35400', mb: 2 }} />
            <Typography variant="h5" fontWeight="bold" sx={{ color: '#d35400', mb: 2 }}>
              {t('Vision')}
            </Typography>
            <Typography sx={{ fontSize: '1.05rem', color: '#555' }}>
              {(t('Text'))}
            </Typography>
          </MotionPaper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default MissionVision;
