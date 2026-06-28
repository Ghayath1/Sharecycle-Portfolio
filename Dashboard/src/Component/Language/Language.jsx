import React from 'react';
import { useTranslation } from 'react-i18next';
import { IconButton, Tooltip } from '@mui/material';

const LanguageToggle = () => {
  const { i18n } = useTranslation();
  const currentLang = i18n.language;

  const toggleLanguage = () => {
    const newLang = currentLang === 'de' ? 'en' : 'de';
    i18n.changeLanguage(newLang);
  };

  const flag = currentLang === 'de'
    ? 'https://flagcdn.com/w40/de.png'
    : 'https://flagcdn.com/w40/gb.png';

  const alt = currentLang === 'de' ? 'Deutsch' : 'English';

  return (
    <Tooltip title={`Sprache: ${alt}`}>
      <IconButton onClick={toggleLanguage}>
        <img
          src={flag}
          alt={alt}
          width="30"
          height="20"
          style={{ borderRadius: '3px' }}
        />
      </IconButton>
    </Tooltip>
  );
};

export default LanguageToggle;
