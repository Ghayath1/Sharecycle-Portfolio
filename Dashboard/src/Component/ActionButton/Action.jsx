import React from 'react';
import { SpeedDial, SpeedDialAction, SpeedDialIcon } from '@mui/material';
import FacebookIcon from '@mui/icons-material/Facebook';
import LinkedInIcon from '@mui/icons-material/LinkedIn';
import WhatsAppIcon from '@mui/icons-material/WhatsApp';
import ContactMailIcon from '@mui/icons-material/ContactMail';

const FloatingActionMenu = () => {
  const actions = [
    { icon: <LinkedInIcon />, name: 'LinkedIn', onClick: () => window.open('https://www.linkedin.com/in/ghayath-al-shawakh-9b21a1252/', '_blank') },
{ icon: <WhatsAppIcon />, name: 'WhatsApp', onClick: () => window.open('https://wa.me/4917664824372', '_blank') },
    { icon: <ContactMailIcon />, name: 'Kontakt', onClick: () => window.open('tel:017664824372') },

  ];

  return (
    <SpeedDial
      ariaLabel="Action Menu"
      sx={{
        position: 'fixed',
        bottom: 16,
        right: 16,
      }}
      icon={<SpeedDialIcon />}
    >
      {actions.map((action) => (
        <SpeedDialAction
          key={action.name}
          icon={action.icon}
          tooltipTitle={action.name}
          onClick={action.onClick}
        />
      ))}
    </SpeedDial>
  );
};

export default FloatingActionMenu;
