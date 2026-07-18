import Foundation
import Postbox

// MARK: Symonagram — marks a message that was deleted on the server but kept locally.
// `deletionTimestamp` is unixtime of when we intercepted the deletion; used by the retention sweep.
public class SGDeletedMessageAttribute: MessageAttribute {
    public let deletionTimestamp: Int32

    public var associatedMessageIds: [MessageId] = []

    public init(deletionTimestamp: Int32) {
        self.deletionTimestamp = deletionTimestamp
    }

    required public init(decoder: PostboxDecoder) {
        self.deletionTimestamp = decoder.decodeInt32ForKey("sgdt", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.deletionTimestamp, forKey: "sgdt")
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
}
