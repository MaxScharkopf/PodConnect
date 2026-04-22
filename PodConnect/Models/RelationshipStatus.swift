//
//  RelationshipStatus.swift
//  PodConnect
//
//  Created by Desiree Astabie on 4/9/26.
//

import Foundation

enum RelationshipStatus {
    case none
    case requestSent
    case friends
}

enum FriendRequestError: LocalizedError {
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent

    var errorDescription: String? {
        switch self {
        case .cannotAddSelf:
            return "You can't send a friend request to yourself."
        case .alreadyFriends:
            return "You are already friends with this user."
        case .requestAlreadySent:
            return "A friend request has already been sent to this user."
        }
    }
}
