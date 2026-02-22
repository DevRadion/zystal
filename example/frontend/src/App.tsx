import { useState } from "react";

declare function handleButtonClick(param1: string, param2: number): void;

function App() {
    const [count, setCount] = useState(0);

    const handleButton: () => void = () => {
        setCount(count + 1);
        handleButtonClick("Count", count);
    };

    return (
        <main className="min-h-screen px-6 py-10 grid place-items-center select-none">
            <section className="w-full max-w-3xl text-center">
                <h1 className="m-0 text-7xl font-bold">Zystal</h1>
                <p className="mx-auto mt-4 max-w-[56ch] text-lg font-medium">
                    Cross-platform self-contained web applications in Zig
                </p>

                <button
                    type="button"
                    className="mt-7 rounded-2xl bg-[#FAF9F5] hover:bg-[#BFBFBF] text-[#141413] px-4 py-2 text-md font-semibold cursor-pointer active:scale-[0.98] transition-transform duration-150"
                    onClick={handleButton}
                >
                    Count: {count}
                </button>
            </section>
        </main>
    );
}

export default App;
