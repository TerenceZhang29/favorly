import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct DevMessageSimulatorTests {
    let world = TestWorld()

    @Test func theOtherPersonInTheNewestClaimedRequestSendsAMessage() async throws {
        world.session.switchUser(to: DemoUsers.chen.id)
        let result = await DevMessageSimulator.receiveMessage(in: world.environment)
        #expect(result == "Dana sent you a message.")
        let messages = try await world.repository.messages(for: TestWorld.ladderID, as: DemoUsers.chen.id)
        #expect(messages.map(\.senderID) == [DemoUsers.dana.id])
        #expect(messages.first?.text == "Hi! Checking in about Hold a ladder while I change a bulb.")
    }

    @Test func withNoClaimedRequestItSaysWhatToDo() async {
        world.session.switchUser(to: DemoUsers.alex.id)
        #expect(await DevMessageSimulator.receiveMessage(in: world.environment) == DevMessageSimulator.noThread)
    }
}
