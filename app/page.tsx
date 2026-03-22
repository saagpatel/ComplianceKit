import { Shield } from "lucide-react";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6">
      <div className="flex items-center gap-3">
        <Shield className="h-10 w-10 text-zinc-900 dark:text-zinc-100" />
        <h1 className="text-4xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">
          ComplianceKit
        </h1>
      </div>
      <p className="text-lg text-zinc-500 dark:text-zinc-400">
        SOC 2 audit readiness for startups. Coming soon.
      </p>
    </div>
  );
}
