import { useEffect, useState } from "react";

declare function handleButtonClick(param1: string): Promise<number>;

function App() {
    const [count, setCount] = useState(0);

    const handleButton: () => void = async () => {
        const result = await handleButtonClick("Count");
        setCount(result);
    };

    useEffect(() => {
        const testEventHandler = (event: Event) => console.log(event);

        window.addEventListener("test-channel", testEventHandler);
        return () =>
            window.removeEventListener("test-channel", testEventHandler);
    }, []);

    return (
        <main className="relative min-h-screen px-6 pb-10 pt-10 select-none">
            <div
                className="absolute left-0 top-0 h-10 w-full bg-white"
                data-zystal-draggable
            />
            <section className="mx-auto flex w-full max-w-3xl flex-col items-center pt-12 text-center sm:pt-16">
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
