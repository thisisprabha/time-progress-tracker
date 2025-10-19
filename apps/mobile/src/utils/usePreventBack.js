import { useNavigation } from 'expo-router';
import { BackHandler } from 'react-native';

export const usePreventBack = () => {
	const navigation = useNavigation();

	// Android back button handler
	const hardwareBackPressHandler = BackHandler.addEventListener(
		'hardwareBackPress',
		() => {
			// Prevent default behavior of leaving the screen
			return true;
		}
	);

	return () => {
		hardwareBackPressHandler.remove();
	};
};
export default usePreventBack;
