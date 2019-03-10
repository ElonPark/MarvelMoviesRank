//
//  LRU.swift
//  MarvelMoviesRank
//
//  Created by Elon on 10/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import Foundation

class Node<K, V> {
    var next: Node?
    var previous: Node?
    var key: K
    var value: V?
    
    init(key: K, value: V?) {
        self.key = key
        self.value = value
    }
}

class LinkedList<K, V> {
    
    var head: Node<K, V>?
    var tail: Node<K, V>?
    
    init() {}
    
    func addToHead(node: Node<K, V>) {
        if head == nil  {
            head = node
            tail = node
        } else {
            let temp = head
            
            head?.previous = node
            head = node
            head?.next = temp
        }
    }
    
    func remove(node: Node<K, V>) {
        if node === head {
            if head?.next != nil {
                head = head?.next
                head?.previous = nil
            } else {
                head = nil
                tail = nil
            }
        } else if node.next != nil {
            node.previous?.next = node.next
            node.next?.previous = node.previous
        } else {
            node.previous?.next = nil
            tail = node.previous
        }
    }
    
    var description : String {
        var number: Int = 0
        var descriptionString = ""
        var current = self.head
        
        while let now = current {
            descriptionString += "\(number). Key: \(now.key)\n"
            current = current?.next
            number += 1
        }
        
        return descriptionString
    }
}


class LRU<K : Hashable, V> : CustomStringConvertible {
    
    let capacity: Int
    var length = 0
    
    private let queue: LinkedList<K, V>
    private var hashTable: [K : Node<K, V>]
    
    var description : String {
        return "LRU Cache (\(length))\n" + queue.description
    }
    
    init(capacity: Int) {
        self.capacity = capacity
        
        self.queue = LinkedList()
        self.hashTable = [K : Node<K, V>](minimumCapacity: self.capacity)
    }
    
    func get(key: K) -> V? {
        if let node = self.hashTable[key] {
            queue.remove(node: node)
            queue.addToHead(node: node)
            
            return node.value
        } else {
            return nil
        }
    }
    
    func set(key: K, value: V?) {
        if let node = hashTable[key] {
            node.value = value
            queue.remove(node: node)
            queue.addToHead(node: node)
        } else {
            let node = Node(key: key, value: value)
            
            if length < capacity {
                queue.addToHead(node: node)
                hashTable[key] = node
                
                length += 1
            } else {
                if let tailKey = queue.tail?.key {
                    hashTable.removeValue(forKey: tailKey)
                }
                
                queue.tail = queue.tail?.previous
                
                if let node = queue.tail {
                    node.next = nil
                }
                
                queue.addToHead(node: node)
                hashTable[key] = node
            }
        }
    }
    
    func removeAll() {
        var current = queue.head
        
        while current != nil {
            current?.previous = nil
            current = current?.next
            current?.previous?.next = nil
        }
        
        queue.head = nil
        queue.tail = nil
        hashTable.removeAll()
        length = 0
    }

    
    subscript (key: K) -> V? {
        get {
            return get(key: key)
        }
        
        set(value) {
            set(key: key, value: value)
        }
    }
}
