import ios_combined
import RxCocoa
import RxSwift

final class SessionViewModel {
    private let disposeBag = DisposeBag()

    // input
    private let viewDidLoadRelay = PublishRelay<Void>()
    private let toggleEmbeddedViewRelay = PublishRelay<Void>()

    func viewDidLoad() {
        viewDidLoadRelay.accept(())
    }

    func toggleEmbeddedView() {
        toggleEmbeddedViewRelay.accept(())
    }

    // output
    let isFocusedOnEmbeddedView: Driver<Bool>
    let sessions: Driver<[Session]>

    // dependencies
    private let bookingSessionProvider: BookingSessionProvider = .init()

    init() {
        let isFocusedOnEmbeddedViewRelay = BehaviorRelay<Bool>(value: true)
        let sessionsRelay = BehaviorRelay<[Session]>(value: [])

        isFocusedOnEmbeddedView = isFocusedOnEmbeddedViewRelay.asDriver()
        sessions = sessionsRelay.asDriver()

        let dataProvider = SessionDataProvider()

        viewDidLoadRelay.asObservable()
            .flatMap { dataProvider.fetchSessions() }
            .bind(to: sessionsRelay)
            .disposed(by: disposeBag)

        toggleEmbeddedViewRelay.asObservable()
            .withLatestFrom(isFocusedOnEmbeddedViewRelay)
            .map { !$0 }
            .bind(to: isFocusedOnEmbeddedViewRelay)
            .disposed(by: disposeBag)
    }

    func bookSession(_ session: Session) {
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        bookingSessionProvider.bookSession(session: session).subscribe(onCompleted: {
            feedback.notificationOccurred(.success)
		}) { _ in
            feedback.notificationOccurred(.error)
        }.disposed(by: disposeBag)
    }
}
