//
//  FaithLockWidgetBundle.swift
//  FaithLockWidget
//
//  Created by Abdoul Rachid Tapsoba on 03/07/2026.
//

import WidgetKit
import SwiftUI

@main
struct FaithLockWidgetBundle: WidgetBundle {
    var body: some Widget {
        FaithLockWidget()
        // Live Activity — requires iOS 16.2 (16.1 has a Dynamic Island bug).
        if #available(iOS 16.2, *) {
            PromoOfferLiveActivity()
        }
    }
}
