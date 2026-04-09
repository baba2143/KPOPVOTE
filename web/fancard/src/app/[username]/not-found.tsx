import Link from "next/link";

export default function NotFound() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-br from-gray-50 to-gray-100">
      <div className="text-center max-w-md">
        <div className="text-6xl mb-4">🔍</div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          FanCardが見つかりません
        </h1>
        <p className="text-gray-600 mb-8">
          このFanCardは存在しないか、非公開に設定されています。
        </p>
        <Link
          href="/"
          className="inline-flex items-center justify-center px-6 py-3 bg-primary-600 text-white rounded-xl hover:bg-primary-700 transition-colors"
        >
          トップページへ
        </Link>
      </div>
    </main>
  );
}
