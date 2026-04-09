import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-br from-purple-50 to-pink-50">
      <div className="text-center max-w-md">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          🎤 FanCard
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          K-POPファンのための推し活名刺
        </p>
        <div className="space-y-4">
          <p className="text-sm text-gray-500">
            FanCardを作成するには、K-VOTE COLLECTORアプリをダウンロードしてください。
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="https://apps.apple.com/app/k-vote-collector"
              className="inline-flex items-center justify-center px-6 py-3 bg-black text-white rounded-xl hover:bg-gray-800 transition-colors"
            >
              <svg className="w-6 h-6 mr-2" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 22C7.79 22.05 6.8 20.68 5.96 19.47C4.25 17 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"/>
              </svg>
              App Store
            </Link>
          </div>
        </div>
      </div>

      <footer className="absolute bottom-4 text-center text-xs text-gray-400">
        <p>Powered by K-VOTE COLLECTOR</p>
      </footer>
    </main>
  );
}
