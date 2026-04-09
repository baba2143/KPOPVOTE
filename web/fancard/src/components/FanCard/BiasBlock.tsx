import { BiasBlockData, BiasSettings } from "@/types/fancard";

interface BiasBlockProps {
  data: BiasBlockData;
  myBias?: BiasSettings[];
  primaryColor: string;
}

export default function BiasBlock({ data, myBias, primaryColor }: BiasBlockProps) {
  // Determine which bias data to show
  const biasToShow = data.showFromMyBias && myBias ? myBias : data.customBias;

  if (!biasToShow || biasToShow.length === 0) {
    return null;
  }

  return (
    <div className="rounded-xl p-4 bg-white/50 backdrop-blur-sm shadow-sm">
      <h3 className="text-sm font-medium text-gray-500 mb-3 flex items-center gap-2">
        <span>💜</span>
        <span>MY BIAS</span>
      </h3>
      <div className="space-y-2">
        {Array.isArray(biasToShow) &&
          biasToShow.map((bias, index) => {
            // Handle both BiasSettings and custom bias format
            const artistName = "artistName" in bias ? bias.artistName : "";
            const memberNames =
              "memberNames" in bias
                ? (bias as BiasSettings).memberNames
                : bias.memberName
                ? [bias.memberName]
                : [];

            return (
              <div
                key={index}
                className="flex items-center gap-3 p-2 rounded-lg hover:bg-white/50 transition-colors"
              >
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-bold"
                  style={{ backgroundColor: primaryColor }}
                >
                  {artistName.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-900 truncate">
                    {artistName}
                  </p>
                  {memberNames.length > 0 && (
                    <p className="text-sm text-gray-500 truncate">
                      {memberNames.join(", ")}
                    </p>
                  )}
                </div>
              </div>
            );
          })}
      </div>
    </div>
  );
}
