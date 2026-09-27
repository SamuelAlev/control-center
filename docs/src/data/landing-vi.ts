import type { LandingCopy } from "./landing-en";

export const vi: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Một chỗ cho ngày làm việc của lập trình viên",
    description:
      "Gom phiếu, rà soát mã, agent AI, cuộc họp và pipeline vào một nơi. Không gian làm việc miễn phí, mã nguồn mở cho máy tính, web và điện thoại.",
    imageAlt:
      "Control Center, công việc lập trình của bạn trong một không gian.",
  },
  nav: {
    product: "Sản phẩm",
    workflows: "Luồng việc",
    features: "Tính năng",
    docs: "Tài liệu",
    demo: "Thử bản demo",
    download: "Tải xuống",
    menu: "Menu",
    primary: "Điều hướng chính",
    mobile: "Điều hướng trên điện thoại",
    home: "Trang chủ Control Center",
    skip: "Chuyển tới nội dung",
    language: "Ngôn ngữ",
    appearance: "Giao diện",
    light: "Sáng",
    dark: "Tối",
    system: "Hệ thống",
  },
  hero: {
    line1: "Nhiều phần đang chuyển động.",
    line2: "Một Control Center.",
    description:
      "Một chỗ cho mã nguồn, agent, bản rà soát và mọi thứ khác làm nên một ngày lập trình.",
    download: "Tải Control Center",
    demo: "Xem bản demo trực tiếp",
    platforms: "macOS, Windows, Linux",
    web: "Cũng có trên web và điện thoại",
  },
  media: {
    phone:
      "Ứng dụng đồng hành trên điện thoại hiện cùng một không gian làm việc, một phê duyệt đang chờ và trạng thái một lượt chạy của agent.",
  },
  tour: {
    label: "Khám phá Control Center",
    previous: "Khung sản phẩm trước",
    next: "Khung sản phẩm sau",
    play: "Phát vòng xem",
    pause: "Tạm dừng vòng xem",
    expand: "Phóng to bản xem trước",
    close: "Đóng bản xem trước",
    preview: "Bản xem trước sản phẩm",
    note: "Nhìn gần hơn vào một ngày lập trình.",
    imageLanguage: "Chỗ dành cho ảnh hoặc video",
    stops: [
      {
        kind: "desk",
        label: "Ngày của bạn",
        title: "Bắt đầu từ việc đang cần bạn.",
        description:
          "Yêu cầu rà soát, phê duyệt và chỗ bị kẹt. Việc kế tiếp nằm sẵn, không phải lục các thẻ.",
        alt: "Hộp thư Control Center gom pull request theo trạng thái rà soát và hiện một chỗ đồng bộ bị kẹt.",
      },
      {
        kind: "agents",
        label: "Agent",
        title: "Để việc tốt có chỗ xảy ra.",
        description:
          "Chạy agent trong worktree Git tách biệt. Theo công cụ của chúng, dẫn việc và giữ ngữ cảnh.",
        alt: "Một cuộc trò chuyện với agent trong Control Center, có ngữ cảnh việc và hoạt động.",
      },
      {
        kind: "review",
        label: "Rà soát mã",
        title: "Đọc phần đổi. Hiểu câu chuyện.",
        description:
          "Diff, thảo luận và kiểm tra ở cùng nhau. Đăng bản rà soát bằng tài khoản của bạn.",
        alt: "Rà soát pull request trong Control Center, với phần mã đổi và ngữ cảnh rà soát.",
      },
      {
        kind: "tickets",
        label: "Phiếu",
        title: "Giữ bước kế tiếp còn nối.",
        description:
          "Theo mức ưu tiên và người phụ trách, đồng bộ Linear, rồi nối cuộc trò chuyện nơi việc được làm.",
        alt: "Bảng phiếu Control Center, việc được gom theo trạng thái.",
      },
      {
        kind: "meetings",
        label: "Cuộc họp",
        title: "Giữ quyết định sau cuộc gọi.",
        description:
          "Ghi và chép lời trên máy chủ của bạn. Khi họp xong, bạn có ghi chú và việc cần làm.",
        alt: "Một cuộc họp trong Control Center, có bản chép lời và thông tin cuộc họp.",
      },
      {
        kind: "pipelines",
        label: "Pipeline",
        title: "Để việc lặp lại thực sự lặp được.",
        description:
          "Dựng một luồng, chọn cách kích hoạt và theo từng bước của lượt chạy.",
        alt: "Khung pipeline Control Center, có các bước luồng và trạng thái chạy.",
      },
    ],
  },
  integrations: {
    title: "Mang theo công cụ bạn đang dùng.",
    note: "Nối qua máy chủ của bạn, không phải thêm một bản sao của ngày làm việc.",
  },
  grid: {
    title: "Những công cụ bạn với tới mỗi ngày.",
    description: "Làm việc, xem phần đã đổi và giữ lại quyết định.",
    more: "Đọc tài liệu",
    items: [
      {
        title: "Agent song song",
        description:
          "Mỗi việc có một worktree Git tách biệt. Theo lượt chạy, dẫn agent hoặc nhận lại mà không đụng phần còn lại.",
        link: "Chạy agent song song",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Rà soát pull request",
        description:
          "Đọc diff cạnh thảo luận và kiểm tra. Thêm một lượt rà soát bằng AI khi nó có ích, rồi đăng bằng tài khoản forge của bạn.",
        link: "Rà soát một pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Phiếu được nối",
        description:
          "Đồng bộ Linear, đặt mức ưu tiên và giao việc. Nối phiếu với cuộc trò chuyện nơi việc được làm xong.",
        link: "Quản lý phiếu",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Ghi chú cuộc họp",
        description:
          "Ghi và chép lời trên máy chủ của bạn. Quyết định và việc cần làm còn đó sau khi cuộc gọi kết thúc.",
        link: "Ghi một cuộc họp",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipeline lặp lại được",
        description:
          "Dựng một luồng một lần. Chạy theo lịch, từ một sự kiện hoặc bằng tay, rồi xem từng bước.",
        link: "Dựng một pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Chuyển đổi tài khoản",
        description:
          "Chọn tài khoản mà mỗi agent được dùng, rồi chuyển đổi giữa các tài khoản mà không mất ngữ cảnh của lượt chạy.",
        link: "Quản lý nhà cung cấp mô hình",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Trình chỉnh sửa nhóm tài khoản trong Control Center, hiển thị các tài khoản mà agent có thể dùng.",
      },
      {
        title: "Hạn mức sử dụng",
        description:
          "Kiểm tra hạn mức của nhà cung cấp và thời điểm đặt lại trước khi bắt đầu lượt chạy tiếp theo.",
        link: "Quản lý chi phí",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Bảng sử dụng trong Control Center hiển thị hạn mức của nhà cung cấp và thời điểm đặt lại.",
      },
      {
        title: "Âm thanh nền và tập trung",
        description:
          "Bắt đầu phiên tập trung có hẹn giờ, tắt tiếng thông báo và điều chỉnh âm thanh nền đang phát.",
        link: "Dùng chế độ tập trung",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Đồng hồ tập trung và bộ điều khiển âm thanh nền trong Control Center.",
      },
      {
        title: "Theo dõi hoạt động",
        description:
          "Theo dõi các agent đang hoạt động và xem chi phí, lượng token cùng độ trễ của các lượt chạy trong không gian làm việc.",
        link: "Xem các lượt chạy của agent",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Giao diện theo dõi hoạt động trong Control Center với các agent đang chạy và thông tin chi tiết về lượt chạy.",
      },
      {
        title: "Trình chỉnh sửa kỹ năng và agent",
        description:
          "Chỉnh sửa kỹ năng trong không gian làm việc và cấu hình mô hình, hướng dẫn, quyền hạn của từng agent.",
        link: "Quản lý kỹ năng",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Trình chỉnh sửa kỹ năng và cài đặt agent trong Control Center.",
      },
    ],
    supporting: [
      {
        title: "Một hộp thư",
        description:
          "Rà soát, phê duyệt và chỗ bị kẹt nằm trong một hàng. Nhảy sang việc kế tiếp bằng bảng lệnh.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Xem từ điện thoại",
        description:
          "Theo các lượt chạy và xử lý phê duyệt mà không phải về bàn.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Giữ sợi chỉ.\nCho tới lúc giao.",
    description: "Việc di chuyển giữa các công cụ. Ngữ cảnh nên đi cùng.",
    label: "Một luồng được nối",
    steps: [
      {
        title: "Bắt đầu bằng phiếu.",
        text: "Đặt mức ưu tiên, ghi người phụ trách và nối cuộc trò chuyện. Phiếu giữ bản ghi.",
        kind: "tickets",
        label: "Ý định",
      },
      {
        title: "Cho việc một chỗ riêng.",
        text: "Bàn một kế hoạch, chuẩn bị worktree tách biệt và chạy agent. Dẫn hoặc nhận lại khi cần.",
        kind: "agents",
        label: "Việc",
      },
      {
        title: "Đưa kết quả vào rà soát.",
        text: "Đọc phần đổi, theo cuộc thảo luận và đăng bằng tài khoản forge của bạn. Câu chuyện vẫn nối với nhau.",
        kind: "review",
        label: "Kết quả",
      },
    ],
  },
  boundaries: {
    title: "Phê duyệt một push trước khi nó chạy.",
    description:
      "Đặt Git push, việc đăng pull request và các thao tác được canh gác khác phía sau một phê duyệt. Xem agent sắp làm gì trước khi có thứ gì đổi.",
    media:
      "Một lượt chạy của agent dừng ở yêu cầu phê duyệt Git push. Hiện lệnh được đề xuất, thư mục làm việc và nút phê duyệt hoặc từ chối.",
    note: "Không có ai đang kết nối để phê duyệt? Thao tác bị từ chối. Quyền do máy chủ của bạn thi hành, không phải do một prompt.",
    link: "Cấu hình phê duyệt thao tác",
  },
  surfaces: {
    title: "Bàn là một chỗ.\nViệc thì không.",
    description:
      "Bắt đầu trên máy tính. Vào từ trình duyệt. Ở gần từ điện thoại. Một máy chủ giữ mọi thứ lại với nhau.",
    desktop: "Máy tính gốc",
    web: "Trong trình duyệt",
    phone: "Ứng dụng đồng hành trên điện thoại",
    note: "Máy chủ của bạn sở hữu dữ liệu và việc thực thi. Thiết bị của bạn vẫn đồng bộ.",
    link: "Tìm nền tảng của bạn",
  },
  faq: {
    title: "Những câu hỏi hay.",
    description: "Vài điều nên biết trước khi bạn ở lại.",
    items: [
      {
        question: "Control Center chỉ dành cho agent AI?",
        answer:
          "Không. Control Center đặt phiếu, pull request, cuộc trò chuyện, cuộc họp, lịch, pipeline, agent và một trình đọc RSS cá nhân vào một không gian làm việc. Agent là một phần của bàn, không phải điều kiện để dùng phần còn lại.",
        links: [{ label: "Xem các tính năng", href: "/vi-VN/#features" }],
      },
      {
        question: "Phiếu khác cuộc trò chuyện ở điểm nào?",
        answer:
          "Phiếu ghi việc và trạng thái của việc đó; việc thực thi diễn ra trong một cuộc trò chuyện. Cuộc trò chuyện có thể chuẩn bị một worktree tách biệt kiểu copy-on-write trước khi agent chạy. Trên Windows, bước chuẩn bị đó dùng Git worktree.",
        links: [{ label: "Đi theo một luồng mẫu", href: "/vi-VN/#workflows" }],
      },
      {
        question: "Agent chạy ở đâu, và máy chủ làm gì?",
        answer:
          "Máy chủ sở hữu cơ sở dữ liệu của không gian làm việc, thông tin đăng nhập, API và việc thực thi agent; máy khách trên máy tính và trình duyệt hiện và điều khiển công việc đó. Worker đội tàu tùy chọn nhận việc được thuê và phát sự kiện, nhưng không giữ cơ sở dữ liệu, thông tin đăng nhập hay ngân sách.",
        links: [
          {
            label: "Đọc hướng dẫn kiến trúc",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Tôi kiểm soát một lượt chạy của agent đến mức nào?",
        answer:
          "Mỗi cuộc trò chuyện có thể dùng Chỉ đề xuất, Hành động khi được duyệt hoặc Hành động tự do. Quyền và sandbox vẫn giới hạn thao tác được phép; yêu cầu phê duyệt không có người duyệt sẽ bị từ chối. Hạn mức ngân sách mềm thì cảnh báo, hạn mức cứng thì tạm dừng, và các lượt chạy giữ nhật ký.",
        links: [{ label: "Xem phần điều khiển", href: "/vi-VN/#boundaries" }],
      },
      {
        question: "Một kế hoạch Orchestrate có tự thuê agent không?",
        answer:
          "Không. Orchestrate có thể tìm hiểu và đề xuất vai trò, phiếu con và một kế hoạch, nhưng việc thuê phải chờ phê duyệt. Plan Studio mở từ dòng kế hoạch trong cuộc trò chuyện gốc; chỉ giao một phiếu thì chưa bắt đầu một lượt chạy.",
        links: [{ label: "Đi theo luồng mẫu", href: "/vi-VN/#workflows" }],
      },
      {
        question: "Tôi chạy agent từ điện thoại đã ghép cặp được không?",
        answer:
          "Điện thoại đã ghép cặp là máy khách mỏng của cùng không gian trên máy chủ, không phải máy thực thi thứ hai. Máy tính, trình duyệt và điện thoại hiện cùng một việc; agent chạy trên máy chủ hoặc trên worker đội tàu được thuê, nếu bạn bật.",
        links: [{ label: "Xem các bề mặt được nối", href: "/vi-VN/#surfaces" }],
      },
      {
        question: "Tôi dùng được những tích hợp nào?",
        answer:
          "Đồng bộ phiếu với Linear đã có; Jira và ClickUp không có bộ chuyển. Sự kiện Google Calendar đã nối chỉ để đọc, và trả lời lời mời chỉ có khi lịch cấp quyền ghi. Luồng Slack có thể nối vào cuộc trò chuyện, và các forge đã nối cung cấp pull request cùng các kiểm tra.",
        links: [{ label: "Đọc sổ tay", href: "/manual/" }],
      },
      {
        question: "Ghi chú cuộc họp và việc cần làm xuất hiện khi nào?",
        answer:
          "Bản chép lời trực tiếp có thể tách người nói trong lúc ghi. Sau khi bạn dừng, agent tóm tắt xử lý cuộc họp và lưu ghi chú, quyết định cùng việc cần làm; ghi âm và xử lý là hai trạng thái khác nhau.",
        links: [{ label: "Xem ngày trong ngữ cảnh", href: "/vi-VN/#day" }],
      },
      {
        question: "Bản demo công khai có phải không gian làm việc thật?",
        answer:
          "Bản demo công khai là một bản dựng riêng, bị khóa, với dữ liệu bịa và agent đi theo kịch bản. Bản ghi và các lượt chạy của nó là ví dụ, không phải việc của bạn.",
        links: [{ label: "Xem bản demo trực tiếp", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Dù lượn 3D. Kéo để xoay góc nhìn và điều hướng. Mũi tên trái và phải dùng để rẽ; mũi tên lên và xuống nghiêng hướng bay lên hoặc xuống. R đặt lại; Space tạm dừng hoặc tiếp tục chuyến bay và gió.",
  },
  install: {
    title: "Ở lại\ncho quen.",
    description:
      "Ngày lập trình kế tiếp có thể bắt đầu ở đây. Miễn phí và mã nguồn mở.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Xem các bản phát hành",
    web: "Mở ứng dụng web",
    phone: "Mở ứng dụng đồng hành trên điện thoại",
    webNote: "Kết nối với máy chủ do bạn chạy.",
    phoneNote: "Ghép điện thoại với máy chủ qua một relay kín.",
    selfHost: "Muốn tự lưu trữ?",
    server: "Chạy máy chủ không giao diện",
    guide: "Đọc hướng dẫn bắt đầu nhanh",
  },
  footer: {
    tagline: "Một chỗ cho ngày làm việc của lập trình viên.",
    resources: "Tài nguyên",
    source: "Mã nguồn trên GitHub",
    compare: "So sánh",
    changelog: "Nhật ký thay đổi",
    about: "Giới thiệu",
    contact: "Liên hệ",
    privacy: "Quyền riêng tư",
    terms: "Điều khoản",
    licenses: "Giấy phép",
    acknowledgements: "Lời cảm ơn",
    made: "Xây ở nơi công khai.",
    top: "Lên đầu trang",
  },
};
