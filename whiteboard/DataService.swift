import Foundation
import SwiftUI
import WidgetKit

class DataService: ObservableObject {
    @Published var currentUser: User? = User(id: "u1", name: "You")
    @Published var whiteboards: [Whiteboard] = []
    @Published var onboardingComplete: Bool = false
    
    private let userDefaultsKey = "whiteboard_user"
    private let onboardingCompleteKey = "onboarding_complete"
    
    init() {
        loadOnboardingStatus()
        loadUser()
        loadWhiteboards()
    }
    
    // MARK: - User Management
    
    func loadOnboardingStatus() {
        onboardingComplete = UserDefaults.standard.bool(forKey: onboardingCompleteKey)
    }
    
    func completeOnboarding() {
        onboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingCompleteKey)
    }
    
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }
    
    func saveUser(_ user: User, completeSetup: Bool = false) {
        self.currentUser = user
        
        // Only save to UserDefaults if we're completing setup or user was already saved
        if completeSetup || UserDefaults.standard.data(forKey: userDefaultsKey) != nil {
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            }
            
            // If we're completing setup, mark onboarding as complete
            if completeSetup {
                completeOnboarding()
            }
        }
    }
    
    func signOut() {
        currentUser = nil
        onboardingComplete = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: onboardingCompleteKey)
    }
    
    // MARK: - Whiteboard Management
    
    func loadWhiteboards() {
        whiteboards = WhiteboardUtility.loadWhiteboards()
        
        // If no whiteboards, create a sample one
        if whiteboards.isEmpty {
            let sampleBoard = Whiteboard(
                name: "Sample Board",
                items: [
                    WhiteboardItem(
                        type: .text,
                        content: "Welcome to your whiteboard!",
                        createdBy: "System",
                        position: CGPoint(x: 180, y: 180)
                    )
                ]
            )
            whiteboards.append(sampleBoard)
            saveWhiteboards()
        }
    }
    
    func saveWhiteboards() {
        WhiteboardUtility.saveWhiteboards(whiteboards)
        
        // Update widgets when whiteboards change
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func createWhiteboard(name: String) -> Whiteboard {
        guard let currentUser = currentUser else {
            fatalError("Cannot create whiteboard without a logged in user")
        }
        
        let newBoard = Whiteboard(
            name: name,
            items: [],
            members: [currentUser.id]
        )
        
        whiteboards.append(newBoard)
        saveWhiteboards()
        return newBoard
    }
    
    func updateWhiteboard(_ whiteboard: Whiteboard) {
        if let index = whiteboards.firstIndex(where: { $0.id == whiteboard.id }) {
            whiteboards[index] = whiteboard
            
            // Move this whiteboard to the front of the array so it appears in the widget
            if index != 0 {
                let updatedBoard = whiteboards.remove(at: index)
                whiteboards.insert(updatedBoard, at: 0)
            }
        } else {
            // If not found, add it at the beginning
            whiteboards.insert(whiteboard, at: 0)
        }
        saveWhiteboards()
    }
    
    func addItemToWhiteboard(whiteboardId: String, item: WhiteboardItem) {
        if let index = whiteboards.firstIndex(where: { $0.id == whiteboardId }) {
            whiteboards[index].items.append(item)
            saveWhiteboards()
        }
    }
    
    // Get a whiteboard associated with a specific group ID
    func getWhiteboardForGroup(groupId: String) -> Whiteboard? {
        // First check if there's a whiteboard with an ID matching the groupId
        if let existingBoard = whiteboards.first(where: { $0.id == groupId }) {
            return existingBoard
        }
        
        // If not found by direct ID match, you could implement additional search logic here
        // For example, if you store group associations in the whiteboard metadata
        
        return nil
    }
    
    // MARK: - Backend Integration (placeholders for future implementation)
    
    func syncWithBackend() {
        // This would connect to your backend service
        // For now, we'll just work with local data
    }
    
    func fetchWhiteboardsFromBackend(completion: @escaping ([Whiteboard]?) -> Void) {
        // This would fetch whiteboards from your backend
        // For the prototype, just return local data
        completion(whiteboards)
    }
    
    func uploadWhiteboardToBackend(_ whiteboard: Whiteboard, completion: @escaping (Bool) -> Void) {
        // This would upload changes to your backend
        // For the prototype, just save locally
        updateWhiteboard(whiteboard)
        completion(true)
    }
} 
