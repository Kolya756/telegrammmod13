import Foundation
import Postbox

// MARK: Symonagram — marks a message that was deleted on the server but kept locally,
// or a self-destruct / view-once media that we kept.
// `deletionTimestamp` is unixtime of when we intercepted it; used by the retention sweep and UI.
// `isSelfDestruct` distinguishes kept view-once/self-destruct media (shown normally with a 👁 mark)
// from deleted messages (dimmed with a 🗑 mark).
public class SGDeletedMessageAttribute: MessageAttribute {
    public let deletionTimestamp: Int32
    public let isSelfDestruct: Bool

    public var associatedMessageIds: [MessageId] = []

    public init(deletionTimestamp: Int32, isSelfDestruct: Bool = false) {
        self.deletionTimestamp = deletionTimestamp
        self.isSelfDestruct = isSelfDestruct
    }

    required public init(decoder: PostboxDecoder) {
        self.deletionTimestamp = decoder.decodeInt32ForKey("sgdt", orElse: 0)
        self.isSelfDestruct = decoder.decodeInt32ForKey("sgsd", orElse: 0) != 0
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.deletionTimestamp, forKey: "sgdt")
        encoder.encodeInt32(self.isSelfDestruct ? 1 : 0, forKey: "sgsd")
    }
}

public extension Message {
    var sgDeletedAttribute: SGDeletedMessageAttribute? {
        for attribute in self.attributes {
            if let attribute = attribute as? SGDeletedMessageAttribute {
                return attribute
            }
        }
        return nil
    }

    var sgIsDeleted: Bool {
        return self.sgDeletedAttribute != nil
    }

    // Dim only kept-deleted messages, never kept self-destruct media (the user wants to see that clearly).
    var sgShouldDim: Bool {
        if let attribute = self.sgDeletedAttribute {
            return !attribute.isSelfDestruct
        }
        return false
    }
}
