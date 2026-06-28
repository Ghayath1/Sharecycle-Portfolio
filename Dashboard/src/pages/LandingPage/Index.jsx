import React from 'react'
import HeroBenner from '../../Component/HeroBanner/HeroBenner'
import InstalllApp  from  '../../Component/InstallApp/InstallApp'
import InterJoinUs from  '../../Component/InterJoinUs/InterJoinUs'
import ContactUs from '../../Component/ContactUs/ContactUs'
import Footer from '../../Component/Footer/Footer'
import MissionVision from '../../Component/MissionVision/MissionVision'
import AboutUs from '../../Component/AboutUs/AboutUs'
import Navbar from '../../Component/NavbarNew/Navbar'
import ActionButtons from '../../Component/ActionButton/Action'

const Index = () => {
  return (
    <div>
      <Navbar/>
      <HeroBenner/>
      <MissionVision/>
      <AboutUs/>
      <InstalllApp/>
      <InterJoinUs/>
      <ContactUs/>
      <Footer/>
      <ActionButtons/>
      
    </div>
  )
}

export default Index
