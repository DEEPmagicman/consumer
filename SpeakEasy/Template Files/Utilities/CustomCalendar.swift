//
//  CustomCalendar.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import FSCalendar

final class CustomCalendar: FSCalendar {

   override init(frame: CGRect) {
      super.init(frame: frame)
       setupCalendar()
   }

   required init?(coder aDecoder: NSCoder) {

       super.init(coder: aDecoder)

       let timeZone = Constant.venueTimeZone
       
       if let projectTimeZone = timeZone {
          self.setValue(projectTimeZone, forKey: "timeZone")
          self.perform(Selector(("invalidateDateTools")))
       }
       setupCalendar()
   }
    
    private func setupCalendar() {
        self.scrollDirection = .vertical
        self.scope = .month
        self.pagingEnabled = false
    }
}
