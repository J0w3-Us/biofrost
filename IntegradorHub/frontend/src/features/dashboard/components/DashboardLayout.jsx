import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';

export function DashboardLayout() {
    return (
        <div className="flex h-screen overflow-hidden bg-white">
            {/* Sidebar - Static/Sticky in Flex container */}
            <Sidebar />

            {/* Main Content Area - Flex Grow */}
            <main className="flex-1 overflow-y-auto scroll-smooth bg-gray-50/30">
                <Outlet />
            </main>
        </div>
    );
}
