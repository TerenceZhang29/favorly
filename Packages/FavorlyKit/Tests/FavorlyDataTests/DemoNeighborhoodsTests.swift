import FavorlyCore
import FavorlyData
import Testing

struct DemoNeighborhoodsTests {
    @Test func rooseveltIslandIsOfferedFirstOnTheIsland() {
        #expect(DemoNeighborhoods.names(near: LocationPresets.cornellTech.location.point).first == "Roosevelt Island")
        #expect(DemoNeighborhoods.names(near: LocationPresets.rooseveltIslandNorth.location.point).first
            == "Roosevelt Island")
    }

    @Test func everyNYCPresetHasNamesAndIthacaHasNone() {
        for preset in LocationPresets.all where preset != LocationPresets.ithaca {
            let names = DemoNeighborhoods.names(near: preset.location.point)
            #expect(!names.isEmpty && names.count <= 8 && Set(names).count == names.count)
        }
        #expect(DemoNeighborhoods.names(near: LocationPresets.ithaca.location.point).isEmpty)
    }

    @Test func theMockRefusesANameThatIsNotOffered() async throws {
        let repository = MockRequestRepository(seed: { [] }, reviewSeed: { [] }, artificialDelay: .zero)
        let alex = UserID(rawValue: "alex")
        let island = LocationPresets.cornellTech.location.point
        #expect(try await repository.neighborhoods(near: island).contains("Roosevelt Island"))
        await #expect(throws: FavorlyError.validation("Choose a neighborhood near you.")) {
            try await repository.create(
                NewRequestDraft(
                    title: "Need rice", details: "", category: .other,
                    location: TaggedLocation(point: island, label: "Seattle")
                ),
                by: alex
            )
        }
        let rice = try await repository.create(
            NewRequestDraft(
                title: "Need rice", details: "", category: .other,
                location: TaggedLocation(point: island, label: "Roosevelt Island"), meetingSpot: "Cornell Tech lobby"
            ),
            by: alex
        )
        #expect(rice.meetingSpot == "Cornell Tech lobby")
        #expect(try await repository.request(id: rice.id).meetingSpot == "Cornell Tech lobby")
    }
}
