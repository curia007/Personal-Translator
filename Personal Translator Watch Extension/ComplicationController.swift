//
//  ComplicationController.swift
//  Personal Translator Watch Extension
//
//  Created by Carmelo I. Uria on 8/11/16.
//  Copyright © 2016 Carmelo I. Uria. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource
{
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        
    }
    
    @nonobjc func getTimelineStartDate(for complication: CLKComplication, withHandler handler: (Date?) -> Void) {
        handler(nil)
    }
    
    @nonobjc func getTimelineEndDate(for complication: CLKComplication, withHandler handler: (Date?) -> Void) {
        handler(nil)
    }
    
    @nonobjc func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void))
    {
        // Call the handler with the current timeline entry
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    @nonobjc func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void)
    {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
}
