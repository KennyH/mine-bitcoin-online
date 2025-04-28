"use client";

import PageHeader from './PageHeader';
import PageFooter from './PageFooter';
import PageBanner from './PageBanner';

type PagePlaceholderProps = {
    title: string;
};

export default function PagePlaceholder({ title }: PagePlaceholderProps){
    return (
        <>
            <PageHeader/>
            <PageBanner/>
            <div className="flex flex-col items-center justify-center min-h-[60vh]">
                <h1 className="text-2xl font-bold mb-2">{title}</h1>
                <p className="text-gray-400">This page is under construction.</p>
            </div>
            <PageFooter/>
        </>
    )
}