import { TextBlockData } from "@/types/fancard";

interface TextBlockProps {
  data: TextBlockData;
}

export default function TextBlock({ data }: TextBlockProps) {
  const alignmentClass = {
    left: "text-left",
    center: "text-center",
    right: "text-right",
  }[data.alignment || "left"];

  return (
    <div className={`p-4 rounded-xl bg-white/50 backdrop-blur-sm ${alignmentClass}`}>
      <p className="text-gray-700 whitespace-pre-wrap">{data.content}</p>
    </div>
  );
}
