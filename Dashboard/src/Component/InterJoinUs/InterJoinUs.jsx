import React from 'react';
import { Box, Typography, Button, Stack } from '@mui/material';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { useTranslation } from 'react-i18next';

const MotionBox = motion(Box);
const MotionTypography = motion(Typography);
const MotionStack = motion(Stack);

const InterjoinUs = () => {
  const { t } = useTranslation();
  const [ref, inView] = useInView({ triggerOnce: true, threshold: 0.6 });

  return (
    <Box
    id="join"
      ref={ref}
      sx={{
        background: 'linear-gradient(to right, #ffd9c2, #fff3eb)',
        textAlign: 'center',
        py: { xs: 8, md: 10 },
        px: 2,
        overflow: 'hidden',
      }}
    >
      <MotionTypography
        variant="h4"
        initial={{ opacity: 0, y: 50 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7 }}
        sx={{ fontWeight: 'bold', color: '#d35400', mb: 2 }}
      >
        {t('Community')}
      </MotionTypography>

      <MotionTypography
        variant="body1"
        initial={{ opacity: 0, y: 50 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, delay: 0.2 }}
        sx={{ color: '#555', maxWidth: 600, mx: 'auto', mb: 4 }}
      >
        {t('Fahrrad')}
      </MotionTypography>

      <MotionStack
        direction={{ xs: 'column', sm: 'row' }}
        spacing={2}
        justifyContent="center"
        initial={{ opacity: 0, y: 50 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, delay: 0.4 }}
      >
        <Button
          variant="contained"
          sx={{
            backgroundColor: '#d35400',
            px: 4,
            py: 1.5,
            borderRadius: 3,
            textTransform: 'none',
            fontWeight: 'bold',
            fontSize: '1rem',
            '&:hover': { backgroundColor: '#e36b17' },
          }}
        >
          {t('Jetzt')}
        </Button>

        <Button
          variant="outlined"
          sx={{
            color: '#d35400',
            borderColor: '#d35400',
            px: 4,
            py: 1.5,
            borderRadius: 3,
            textTransform: 'none',
            fontWeight: 'bold',
            fontSize: '1rem',
            '&:hover': {
              backgroundColor: '#fff3eb',
              borderColor: '#e36b17',
            },
          }}
        >
          {t('Mehr')}
        </Button>
      </MotionStack>
    </Box>
  );
};

export default InterjoinUs;
