export interface Theme {
    colors: {
        primary: string;
        secondary: string;
        white: string;
        primaryText: string;
        searchCategory: string;
        quaternary: string;
    };
    sizes: {
        width: number;
        height: number;
        padding: number;
        title: number;
        subtitle: number;
        body: number;
        bottomTabHeight: number;
        headerHeight: number;
        iconMedium: number;
        lottieIconHeight: number;
    };
}

export interface UploadRequest {
    id: string;
    title: string;
    description: string;
    status: 'pending' | 'approved' | 'rejected';
    createdAt: Date;
    userId: string;
    fileUrl: string;
    university: string;
    course: string;
    branch: string;
}

export interface UserRequestsState {
    NewRequests: UploadRequest[];
    loading: boolean;
    loadingRequests: boolean;
    error: string | null;
}

export interface BootReducerState {
    customClaims: {
        branchManagerDetails: {
            university: string;
            course: string;
            branches: string[];
        };
    };
}

export interface RootState {
    UserRequestsReducer: UserRequestsState;
    theme: Theme;
    bootReducer: BootReducerState;
} 