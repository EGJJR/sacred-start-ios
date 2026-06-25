export const SCRIPTURE_TOOLS = [
  {
    type: "function",
    function: {
      name: "lookup_passage",
      description:
        "Fetch exact KJV text for a Bible reference. Use when the user names or asks about a specific passage.",
      parameters: {
        type: "object",
        properties: {
          reference: {
            type: "string",
            description: 'e.g. "John 3:16", "Psalm 23", "Philippians 4:6-7"',
          },
        },
        required: ["reference"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "discover_passages",
      description:
        "Find curated verses for a mood, topic, or keyword. Use when the user wants a passage but did not name one.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string" },
          topics: {
            type: "array",
            items: {
              type: "string",
              enum: [
                "peace",
                "anxiety",
                "hope",
                "gratitude",
                "rest",
                "guidance",
                "strength",
                "love",
                "faith",
                "grief",
                "forgiveness",
                "courage",
                "provision",
                "presence",
                "joy",
                "promises",
              ],
            },
          },
          limit: { type: "integer", default: 3 },
        },
        required: ["query"],
      },
    },
  },
] as const;

export const MAX_TOOL_ROUNDS = 2;
