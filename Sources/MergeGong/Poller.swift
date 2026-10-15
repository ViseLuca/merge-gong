import Foundation
import MergeGongCore

/// Polls the watched repos off the main thread, each at its service's interval.
final class Poller {
    typealias Job = (repo: RepoRef, provider: Provider)
    typealias Results = [(repo: RepoRef, result: Result<[PullRequest], Error>)]

    /// Called on the main queue after each round.
    var onResults: ((Results) -> Void)?

    private let worker = DispatchQueue(label: "merge-gong.poll")
    private var timers: [Timer] = []
    /// Bumped on every restart so rounds still in flight for the old jobs are dropped.
    private var generation = 0

    /// Replaces the jobs and polls them right away.
    func start(_ jobs: [Job]) {
        stop()
        for (interval, group) in Dictionary(grouping: jobs, by: { $0.provider.kind.pollInterval }) {
            poll(group)
            timers.append(Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.poll(group)
            })
        }
    }

    func stop() {
        generation += 1
        timers.forEach { $0.invalidate() }
        timers = []
    }

    private func poll(_ jobs: [Job]) {
        let generation = generation
        worker.async { [weak self] in
            let results = jobs.map { job in (job.repo, Result { try job.provider.merges(repo: job.repo.path) }) }
            DispatchQueue.main.async {
                guard let self, self.generation == generation else { return }
                self.onResults?(results)
            }
        }
    }
}
